ad_page_contract {
    Product add/edit
} {
    item_id:naturalnum,optional
}

# Must be an existing acs_object class on the system.
::alt::Package initialize
set class "::alt::Product"

if {[info exists item_id] && [::xo::db::Class exists_in_db -id $item_id]} {
    set page_title #altered.Edit_Product#
    set data [::xo::db::Class get_instance_from_db -id $item_id]    
} else {
    set page_title #altered.Create_Product#
    set data [$class new]    
}

set context [list [list list #altered.Products_List#] $page_title]

ad_form -name addedit \
    -form {
	{item_id:key}
	{code:text,optional
	    {label #altered.Code#}
	    {html {readonly ""}}
	}
	{name:text
	    {label #altered.Name#}
	}
	{description:text
	    {label #altered.Description#}
	}
    } -edit_request {
	foreach field {code name description} {
	    set $field [$data set $field]
	}
    } -on_submit {
	if {[::xo::dc 0or1row check "
           select 1 from [$class table_name]
            where code = :code 
              and product_id <> :item_id"]} {
	    template::form::set_error addedit code #altered.Code_is_not_unique#
	    break
	}
	foreach field {code name description} {
	    $data set $field [set $field]
	}
    } -new_data {
	$data save_new
    } -edit_data {
	$data save
    } -after_submit {
	ad_returnredirect list
	ad_script_abort
    }
