ad_page_contract {

  @author Claudio Pasolini
  @cvs-id bid-line-add-edit.tcl

} {
    invoice_id:naturalnum
    item_id:naturalnum,optional
}

set class ::alt::SaleInvoiceLine

set package_key [ad_conn package_key]
template::head::add_javascript -src  "/resources/$package_key/javascript/jquery-ui/js/jquery-1.8.0.min.js" -order 0
template::head::add_javascript -src  "/resources/$package_key/javascript/jquery-ui/js/jquery-ui-1.8.23.custom.min.js" -order 1
template::head::add_css        -href "/resources/$package_key/javascript/jquery-ui/development-bundle/themes/base/jquery.ui.all.css"
template::head::add_javascript -src "/resources/$package_key/javascript/ah-util.js" -order 2

set this_url [export_vars -base [ad_conn url] -entire_form -no_empty]

# header data
set invoice [::xo::db::Class get_instance_from_db -id $invoice_id]
set invoice_num  [$invoice set invoice_num]
set invoice_date [lc_time_fmt [$invoice set date] %x]
set confirmed_p  [$invoice set confirmed_p]
set party_id     [$invoice set party_id]

if {$confirmed_p} {
    set conf_reset_url [export_vars -base "../../call" {{m reset} {item_id $invoice_id} {return_url $this_url}}]
} else {
    set conf_reset_url [export_vars -base "../../call" {{m confirm} {item_id $invoice_id} {return_url $this_url}}]
}

set party [::xo::db::Class get_instance_from_db -id $party_id]
set party_name [$party set title]

set mode edit
if {[info exists item_id] && [::xo::db::Class exists_in_db -id $item_id]} {
    set data [::xo::db::Class get_instance_from_db -id $item_id]
    if {!$confirmed_p} {
	set page_title "#altered.Edit_Sale_Invoice_Line#"
    } else {
	set page_title "#altered.View_Sale_Invoice_Line#"
	set mode view
    }
} else {
    if {!$confirmed_p} {
	set page_title "#altered.Create_Sale_Invoice_Line#"
	set data [$class new -volatile]
    } else {
	set page_title "#altered.SaleInvoiceLines#"
    }
}

set context [list [list list #altered.Sale_Invoices_List#] $page_title]

set show_form_p [expr {[info exists data]}]
if {$show_form_p} {
    set form_name lineaddedit
    ad_form -name $form_name \
        -export {invoice_id item_id} \
        -form {
	    {line_num:integer,optional
		{label "#altered.Line_Num#"}
		{html {readonly ""}}
	    }
	    {product_id:integer,optional
		{label "#altered.Product#"}
	    }
	    {description:text(textarea),optional,nospell
		{label "#altered.Description#"}
		{html {rows 3 cols 50 wrap soft}}
	    }
	    {unity_id:text(select),optional
		{options {{"..." ""} [alt::um::selbox]}}
		{label "#altered.Unit_of_Measurement#"}
		{html {readonly ""}}
	    }
	    {vat_id:text(select),optional
		{options {{"..." ""} [alt::vat::selbox]}}
		{label "#altered.VAT#"}
	    }
	    {qty:text
		{label "#altered.Quantity#"}
	    }
	    {price:text
		{label "#altered.Price#"}
	    }
	    {deductible_tax_amount:text,optional
		{label "#altered.Deductible_Tax_Amount#"}
	    }
	    {undeductible_tax_amount:text,optional
		{label "#altered.Undeductible_Tax_Amount#"}
	    }
	} -on_request {

	    if {[$data exists object_id]} {
		foreach var {
		    product_id description qty price vat_id unity_id
		    undeductible_tax_amount deductible_tax_amount
		} {
		    template::element::set_value $form_name $var [$data set $var]
		}
	    }

	} -on_refresh {

	    if {$product_id ne ""} {
	    	set product [::xo::db::Class get_instance_from_db -id $product_id]
		foreach var {description price unity_id vat_id} {
		    template::element::set_value $form_name $var [$product set $var]
		}
	    }

	} -on_submit {

	    # if {![template::form is_valid $form_name]} break

	    $data set invoice_id  $invoice_id
	    $data set product_id  $product_id
	    $data set unity_id    $unity_id
	    $data set vat_id      $vat_id
	    $data set qty         $qty
	    $data set price       $price
	    $data set undeductible_tax_amount $undeductible_tax_amount
	    $data set deductible_tax_amount   $deductible_tax_amount
	    $data set description $description

	    if {$mode eq "edit"} {
		if {![$data exists object_id]} {
		    ::xo::dc transaction { $data save_new }
		} else {
		    ::xo::dc transaction { $data save }
		}
	    }

	} -after_submit {
	    ad_returnredirect [export_vars -base [ad_conn url] {invoice_id}]
	    ad_script_abort
	}

    set field product_id
    set package_url [ad_conn package_url]

    template::add_body_script -type text/javascript -script [subst -nocommands {
	\$(function() {
	    var comboFields = [['$field', '${package_url}ac-ws/products']];
	    ahAutocomplete(comboFields);

	    var e = document.getElementById('$form_name').elements.namedItem('$field').previousElementSibling;
	    if (e !== null) {
		e.addEventListener('blur', function (event) {
		    if (this.value != '') {
			var form = document.getElementById('$form_name');
			form.__refreshing_p.value='1';
			form.submit();
		    }
		}, false);
	    }
	});
    }]
}
