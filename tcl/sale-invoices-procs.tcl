::xo::library doc {

    Purc invoices

    @author Antonio Pisano

}

::xo::library require base-procs

namespace eval ::alt {

    #
    ## Sale invoice
    #

    ::xo::db::Class create SaleInvoice \
	-id_column "invoice_id"	\
	-table_name "alt_sale_invoices" \
	-pretty_name   "#altered.SaleInvoice#" \
	-pretty_plural "#altered.SaleInvoices#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create invoice_num -not_null true
	    ::xo::db::Attribute create invoice_year -datatype integer -not_null true	    
	    ::xo::db::Attribute create date -datatype date
	    ::xo::db::Attribute create party_id -datatype integer -references "[::alt::Party table_name]([alt::Party id_column])"
	    ::xo::db::Attribute create location_id -datatype integer -references "[::alt::Location table_name]([alt::Location id_column])"
	    ::xo::db::Attribute create description
	    ::xo::db::Attribute create confirmed_p -datatype boolean -default false	    
	}    

    foreach col {party_id location_id} {
	::xo::db::require index -table [::alt::SaleInvoice table_name] -col $col
    }

    ::xo::db::require index \
	-table [::alt::SaleInvoice table_name] \
	-unique true -col "invoice_num,invoice_year"

    SaleInvoice instproc gen_number {} {
    }
    
    SaleInvoice instproc save_new {} {
	set gen_number_p [expr {${:invoice_num} eq ""}]
	if {$gen_number_p} {
	    # TODO: unwire this
	    set counter_id [::xo::dc get_value counter {
		select counter_id from alt_counters where code = '002'}]
	    set c [::xo::db::Class get_instance_from_db -id $counter_id]
	    
	    set number [$c next -date ${:date}]
	    set :invoice_num [format "%06s" $number]
	    set :invoice_num ${:invoice_num}/${:invoice_year}
	}
	
	set invoice_id [next]

	if {$gen_number_p} {
	    $c assign_number \
		-number      $number \
		-date        ${:date} \
		-document_id ${:invoice_id}
	}
    }

    SaleInvoice instproc confirm {} {
	if {${:confirmed_p}} return
	set amount [::xo::dc get_value get_amount "
         select coalesce(sum(price * qty), 0) 
           from [::alt::SaleInvoiceLine table_name]
          where invoice_id = ${:invoice_id}"]
	set d [PaymentDate new -volatile \
		   -document_id ${:invoice_id} \
		   -amount      $amount \
		   -due_date    ${:date}]
	$d save_new
	set :confirmed_p true
	:save
    }

    SaleInvoice instproc reset {} {
	if {!${:confirmed_p}} return
	foreach date [[alt::PaymentDate get_instances_from_db \
			   -select_attributes {object_id} \
			   -where_clause "and document_id = ${:object_id}"] children] {
	    $date delete
	}
	set :confirmed_p false
	:save
    }

    #
    ## Sale invoice line
    #

    ::xo::db::Class create SaleInvoiceLine \
	-id_column "invoice_line_id" \
    	-table_name "alt_sale_invoice_lines" \
	-pretty_name   "#altered.SaleInvoiceLine#" \
	-pretty_plural "#altered.SaleInvoiceLines#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create invoice_id \
		-datatype integer -references "[::alt::SaleInvoice table_name]([alt::SaleInvoice id_column])" -not_null true
	    ::xo::db::Attribute create product_id \
		-datatype integer -references "[::alt::Product table_name]([alt::Product id_column])"
	    ::xo::db::Attribute create description
	    ::xo::db::Attribute create qty -datatype number
	    ::xo::db::Attribute create price -datatype number -default 0
	    ::xo::db::Attribute create line_num -datatype integer -not_null true
	    ::xo::db::Attribute create unity_id -datatype integer \
		-references "[::alt::Unity table_name]([alt::Unity id_column])" -index true	    
	}

    foreach col {invoice_id product_id} {
	::xo::db::require index -table [::alt::SaleInvoiceLine table_name] -col $col
    }

    SaleInvoiceLine instproc get_defaults {} {
	if {[info exists :product_id]} {
	    if {${:description} eq ""} {
		set :description [::xo::dc get_value "
                select name from alt_products 
                 where product_id = ${:product_id}" ""]
	    }
	    if {${:price} eq ""} {
		set :price [::xo::dc get_value "
                select price from alt_products 
                 where product_id = ${:product_id}" ""]
	    }
	    if {[info exists :unity_id] && ${:unity_id} eq ""} {
		set :unity_id [::xo::dc get_value "
                select unity_id from alt_products 
                 where product_id = ${:product_id}" ""]
	    }
	}
    }

    SaleInvoiceLine instproc save_new {} {
	set :line_num [::xo::dc get_value max "
	    select coalesce(max(line_num), 0) 
              from [[:class] table_name]
            where invoice_id = ${:invoice_id}" 0]
	incr :line_num
	:get_defaults
	next
    }

    SaleInvoiceLine instproc save {} {
	:get_defaults
	next
    }
    
    ::xo::db::require view alt_sale_invoicesi "
          select i.*,
                 p.code as party_code,
                 p.title as party_name, 
                 coalesce(am.amount, 0) as amount,
                 coalesce(am.paid_amount, 0) as paid_amount
          from [::alt::SaleInvoice table_name] i
               left join alt_document_amountsi am on i.[alt::SaleInvoice id_column] = am.document_id,
               [::alt::Party table_name] p
            where i.party_id = p.[::alt::Party id_column]" \
	-rebuild_p true

    ::xo::db::require view alt_sale_invoice_linesi "
          select l.*,
                 p.code as product_code,
                 p.name as product_name,
                 p.description as product_description
          from [::alt::SaleInvoiceLine table_name] l,
               [::alt::Product table_name] p
            where l.product_id = p.[alt::Product id_column]" \
	-rebuild_p true
    
}
