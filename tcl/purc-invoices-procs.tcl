::xo::library doc {

    Purc invoices

    @author Antonio Pisano

}

::xo::library require base-procs

namespace eval ::alt {

    #
    ## Purchase invoice
    #

    ::xo::db::Class create PurchaseInvoice \
	-id_column "invoice_id"	\
	-table_name "alt_purchase_invoices" \
	-pretty_name   "#altered.PurchaseInvoice#" \
	-pretty_plural "#altered.PurchaseInvoices#" \
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
	::xo::db::require index -table [::alt::PurchaseInvoice table_name] -col $col
    }

    PurchaseInvoice proc renumber {year} {
	set num 1
	set year_start $year-01-01
	set year_end $year-12-31

	foreach invoice_id [::xo::dc list get_sorted_year_invoices {
	    select invoice_id from alt_purchase_invoices
	    where date between :year_start and :year_end
	    order by date asc, invoice_id asc
	}] {
	    set invoice_num [string repeat 0 [expr {6 - [string length $num]}]]$num/$year
	    ::xo::dc dml move_to_temp {
		update alt_purchase_invoices set
		invoice_num = :invoice_num || '-temp'
		where invoice_num = :invoice_num
	    }
	    ::xo::dc dml renumber {
		update alt_purchase_invoices set
		invoice_num = :invoice_num
		where invoice_id = :invoice_id
	    }
	    incr num
	}
    }

    ::xo::db::require index \
	-table [::alt::PurchaseInvoice table_name] \
	-unique true -col "invoice_num,invoice_year"

    PurchaseInvoice instproc gen_number {} {
    }

    PurchaseInvoice instproc save_new {} {
	set gen_number_p [expr {${:invoice_num} eq ""}]
	if {$gen_number_p} {
	    # TODO: unwire this
	    set counter_id [::xo::dc get_value counter {
		select counter_id from alt_counters where code = '001'}]
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

    PurchaseInvoice instproc calc_amount {} {
	return [::xo::dc get_value get_amount "
         select coalesce(
             sum((price + deductible_tax_amount + undeductible_tax_amount) * qty)
           , 0)
           from [::alt::PurchaseInvoiceLine table_name]
          where invoice_id = ${:invoice_id}"]
    }

    PurchaseInvoice instproc confirm {} {
	if {${:confirmed_p}} return
	set d [PaymentDate new -volatile \
		   -document_id ${:invoice_id} \
		   -amount      [:calc_amount] \
		   -due_date    ${:date}]
	$d save_new
	set :confirmed_p true
	:save
    }

    PurchaseInvoice instproc reset {} {
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
    ## Purchase invoice line
    #

    ::xo::db::Class create PurchaseInvoiceLine \
	-id_column "invoice_line_id" \
    	-table_name "alt_purchase_invoice_lines" \
	-pretty_name   "#altered.PurchaseInvoiceLine#" \
	-pretty_plural "#altered.PurchaseInvoiceLines#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create invoice_id \
		-datatype integer -references "[::alt::PurchaseInvoice table_name]([alt::PurchaseInvoice id_column])" -not_null true
	    ::xo::db::Attribute create product_id \
		-datatype integer -references "[::alt::Product table_name]([alt::Product id_column])"
	    ::xo::db::Attribute create description
	    ::xo::db::Attribute create qty -datatype number
	    ::xo::db::Attribute create price -datatype number -default 0
	    ::xo::db::Attribute create deductible_tax_amount -datatype number -default 0
	    ::xo::db::Attribute create undeductible_tax_amount -datatype number -default 0
	    ::xo::db::Attribute create line_num -datatype integer -not_null true
	    ::xo::db::Attribute create unity_id -datatype integer \
		-references "[::alt::Unity table_name]([alt::Unity id_column])" -index true
	    ::xo::db::Attribute create vat_id -datatype integer \
		-references "[::alt::VAT table_name]([alt::VAT id_column])" -index true
	}

    foreach col {invoice_id product_id} {
	::xo::db::require index -table [::alt::PurchaseInvoiceLine table_name] -col $col
    }

    PurchaseInvoiceLine instproc get_defaults {} {
	if {[info exists :product_id]} {
	    if {${:description} eq ""} {
		set :description [::xo::dc get_value get_name "
                select name from alt_products
                 where product_id = ${:product_id}" ""]
	    }
	    if {${:price} eq ""} {
		set :price [::xo::dc get_value get_price "
                select price from alt_products
                 where product_id = ${:product_id}" ""]
	    }
	    if {[info exists :unity_id] && ${:unity_id} eq ""} {
		set :unity_id [::xo::dc get_value get_um "
                select unity_id from alt_products
                 where product_id = ${:product_id}" ""]
	    }
	}

	if {${:vat_id} ne "" && ${:price} ne "" &&
	    (${:undeductible_tax_amount} eq "" || ${:deductible_tax_amount} eq "")} {
	    set vat [::xo::db::Class get_instance_from_db -id ${:vat_id}]
	    set vat_amounts [$vat calc_amounts ${:price}]
	    if {${:deductible_tax_amount} eq ""} {
		set :deductible_tax_amount [lindex $vat_amounts 0]
	    }
	    if {${:undeductible_tax_amount} eq ""} {
		set :undeductible_tax_amount [lindex $vat_amounts 1]
	    }
	}
    }

    PurchaseInvoiceLine instproc save_new {} {
	set :line_num [::xo::dc get_value max "
	    select coalesce(max(line_num), 0)
              from [[:class] table_name]
            where invoice_id = ${:invoice_id}" 0]
	incr :line_num
	:get_defaults
	next
    }

    PurchaseInvoiceLine instproc save {} {
	:get_defaults
	next
    }

    ::xo::db::require view alt_purchase_invoicesi "
          select i.*,
                 p.code as party_code,
                 p.title as party_name,
                 coalesce(am.amount, 0) as amount,
                 coalesce(am.paid_amount, 0) as paid_amount
          from [::alt::PurchaseInvoice table_name] i
               left join alt_document_amountsi am on i.[alt::PurchaseInvoice id_column] = am.document_id,
               [::alt::Party table_name] p
            where i.party_id = p.[::alt::Party id_column]" \
	-rebuild_p true

    ::xo::db::require view alt_purchase_invoice_linesi "
          select l.*,
                 p.code as product_code,
                 p.name as product_name,
                 p.description as product_description
          from [::alt::PurchaseInvoiceLine table_name] l,
               [::alt::Product table_name] p
            where l.product_id = p.[alt::Product id_column]" \
	-rebuild_p true

}
