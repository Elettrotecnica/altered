ad_page_contract {
    Product add/edit
} {
    document_id:naturalnum
    item_id:naturalnum,optional
    return_url:optional
}

# Must be an existing acs_object class on the system.
::alt::Package initialize
set class "::alt::PaymentDate"

if {[info exists item_id] && [::xo::db::Class exists_in_db -id $item_id]} {
    set page_title #altered.Edit_Payment_Date#
    set data [::xo::db::Class get_instance_from_db -id $item_id]
} else {
    set page_title #altered.Create_Payment_Date#
    set data [$class new]
}

if {![info exists return_url]} {
    set return_url list?document_id=$document_id
}

set context [list [list $return_url #altered.Payment_Dates_List#] $page_title]

set form_name addedit
ad_form -name $form_name \
    -export {item_id document_id return_url} \
    -form {
	{due_date:date,optional
	    {label "#altered.Due_Date#"}
	    {html {length 20}}
	}
	{closing_date:date,optional
	    {label "#altered.Closing_Date#"}
	    {html {length 20}}
	}
	{amount:text
	    {label #altered.Amount#}
	    {html {readonly ""}}
	}
	{paid_amount:text
	    {label #altered.Paid_Amount#}
	}
    } -on_request {
	if {[$data exists object_id]} {
	    foreach var {due_date closing_date} {
		set date_widget [split [string range [$data set $var] 0 9] -]
		template::element::set_value $form_name $var $date_widget
	    }
	    foreach var {amount} {
		template::element::set_value $form_name $var [$data set $var]
	    }
	    set paid_amount [::xo::dc get_value paid_amount {
		select amount from alt_document_amountsi
		where document_id = :document_id}]	    
	} else {
	    set paid_amount [::xo::dc get_value paid_amount {
		select amount - paid_amount from alt_document_amountsi
		where document_id = :document_id}]
	}
	template::element::set_value $form_name paid_amount $paid_amount
    } -on_submit {
	set due_date_ansi     [template::util::date::get_property ansi $due_date]
	$data set due_date $due_date_ansi
	set closing_date_ansi [template::util::date::get_property ansi $closing_date]
	$data set closing_date $closing_date_ansi
	
	foreach var {paid_amount} {
	    $data set $var [set $var]
	}

	::xo::dc transaction { $data pay }

    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }
