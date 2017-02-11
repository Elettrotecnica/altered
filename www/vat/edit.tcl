ad_page_contract {
    VAT add/edit
} {
    item_id:naturalnum,optional
}

# Must be an existing acs_object class on the system.
::alt::Package initialize
set class "::alt::VAT"

if {[info exists item_id] && [::xo::db::Class exists_in_db -id $item_id]} {
    set page_title #altered.Edit_VAT#
    set data [::xo::db::Class get_instance_from_db -id $item_id]    
} else {
    set page_title #altered.Create_VAT#
    set data [$class new]    
}

set context [list [list list #altered.VATs_List#] $page_title]

set form_name addedit
ad_form -name $form_name \
    -export {item_id} \
    -form {
	{code:text,optional
	    {label #altered.Code#}
	}
	{name:text
	    {label #altered.Name#}
	}
	{rate:text,optional
	    {label #altered.Rate#}
	}
	{undeductible_rate:text,optional
	    {label #altered.Undeductible_Rate#}
	    {value 0}
	}
    } -on_request {
	if {[$data exists object_id]} {
	    foreach var {code name rate undeductible_rate} {
		template::element::set_value $form_name $var [$data set $var]
	    }
	}
    } -on_submit {
	set object_id [expr {[$data exists object_id] ? [$data set object_id] : ""}]
	if {[::xo::dc 0or1row check "
           select 1 from [$class table_name]
            where code = :code 
              and [$class id_column] <> :object_id"]} {
	    template::form::set_error $form_name code #altered.Code_is_not_unique#
	    break
	}
	foreach field {code name rate undeductible_rate} {
	    $data set $field [set $field]
	}

	if {![$data exists object_id]} { 
	    ::xo::dc transaction { $data save_new }
	} else {
	    ::xo::dc transaction { $data save }
	}
	
    } -after_submit {
	ad_returnredirect list
	ad_script_abort
    }
