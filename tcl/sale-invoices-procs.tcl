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

    SaleInvoice instproc delete {} {
	if {${:confirmed_p}} return
	::xo::dc dml delete "
	    delete from alt_sale_invoice_lines
	    where invoice_id = ${:invoice_id}"
	next
    }

    SaleInvoice instproc calc_amount {} {
	return [::xo::dc get_value get_amount "
         select coalesce(
             sum((price + deductible_tax_amount + undeductible_tax_amount) * qty)
           , 0)
           from [::alt::SaleInvoiceLine table_name]
          where invoice_id = ${:invoice_id}"]
    }

    SaleInvoice instproc confirm {} {
	if {${:confirmed_p}} return
	set d [PaymentDate new -volatile \
		   -document_id ${:invoice_id} \
		   -amount      [:calc_amount] \
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

    SaleInvoice instproc print {} {
	# header data
	set invoice_num  ${:invoice_num}
	set invoice_date [lc_time_fmt ${:date} %x]

	# party data
	set party [::xo::db::Class get_instance_from_db -id ${:party_id}]
	set party_name [$party set title]
	set vat_number [$party set vat_number]
	set tax_code   [$party set tax_code]

	# location data
	set location_id [expr {${:location_id} ne "" ? ${:location_id} : [$party get_main_location]}]
	set location [::xo::db::Class get_instance_from_db -id $location_id]
	set address [$location format]	

	# lines
	set tot_amount 0
	set tot_tax_amount 0
	db_multirow -local lines get_lines "
	    select
	       p.code,
	       coalesce(l.description, coalesce(p.description, p.name)) as name,
               (select name from [::alt::VAT table_name]
                 where vat_id = l.vat_id) as vat_name,
	       l.price,
	       l.qty,
	       l.price * l.qty as amount,
	       (l.deductible_tax_amount + l.undeductible_tax_amount) * l.qty as tax_amount
	    from [::alt::SaleInvoiceLine table_name] l,
	         [::alt::Product table_name] p
	   where l.invoice_id = ${:invoice_id}
	     and l.product_id = p.product_id
	" {
	    set tot_amount     [expr {$tot_amount + $amount}]
	    set tot_tax_amount [expr {$tot_tax_amount + $tax_amount}]

	    set amount     [lc_numeric [format "%.2f" $amount]]
	    set tax_amount [lc_numeric [format "%.2f" $tax_amount]]
	    set price      [lc_numeric [format "%.2f" $price]]
	    set qty        [lc_numeric $qty]
	}

	set final_amount   [format "%.2f" [expr {$tot_amount + $tot_tax_amount}]]
	set tot_amount     [format "%.2f" $tot_amount]
	set tot_tax_amount [format "%.2f" $tot_tax_amount]

	set tot_amount     [lc_numeric $tot_amount]
	set tot_tax_amount [lc_numeric $tot_tax_amount]
	set final_amount   [lc_numeric $final_amount]

	set fodt_file [ad_tmpnam].fodt

	# this method will use currently executed adp as template for
	# the generation of the pdf. This means the adp file should be
	# in fact a fodt document.
	set fodt_template [ad_conn file]

	# compile the template and generate fodt markup
	set code [ns_memoize [list template::adp_compile -file $fodt_template]]
	set wfd [open $fodt_file w]
	fconfigure $wfd -encoding utf-8
	puts $wfd [string trim [template::adp_eval code]]
	close $wfd

	set pdf_file [alt::office::convert $fodt_file pdf]

	ns_set update [ns_conn outputheaders] content-disposition "attachment; filename=print.pdf"
	ns_returnfile 200 "application/pdf" $pdf_file

	file delete $fodt_file $pdf_file

	ad_script_abort
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
	    ::xo::db::Attribute create deductible_tax_amount -datatype number -default 0
	    ::xo::db::Attribute create undeductible_tax_amount -datatype number -default 0
	    ::xo::db::Attribute create line_num -datatype integer -not_null true
	    ::xo::db::Attribute create unity_id -datatype integer \
		-references "[::alt::Unity table_name]([alt::Unity id_column])" -index true
	    ::xo::db::Attribute create vat_id -datatype integer \
		-references "[::alt::VAT table_name]([alt::VAT id_column])" -index true
	}

    foreach col {invoice_id product_id} {
	::xo::db::require index -table [::alt::SaleInvoiceLine table_name] -col $col
    }

    SaleInvoiceLine instproc get_defaults {} {
	set gross_p false
	if {${:price} eq ""} {
	    set :price ${:gross_price}
	    set gross_p true
	}
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
	    set vat_amounts [$vat calc_amounts -gross_p $gross_p ${:price}]
	    set :price [lindex $vat_amounts 2]
	    if {${:deductible_tax_amount} eq ""} {
		set :deductible_tax_amount [lindex $vat_amounts 0]
	    }
	    if {${:undeductible_tax_amount} eq ""} {
		set :undeductible_tax_amount [lindex $vat_amounts 1]
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
