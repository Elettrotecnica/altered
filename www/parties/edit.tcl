ad_page_contract {
    Product add/edit
} {
    item_id:naturalnum,optional
}

# Must be an existing acs_object class on the system.
::alt::Package initialize
set class "::alt::Party"

if {[info exists item_id] && [::xo::db::Class exists_in_db -id $item_id]} {
    set page_title #altered.Edit_Party#
    set data [::xo::db::Class get_instance_from_db -id $item_id]
} else {
    set page_title #altered.Create_Party#
    set data [$class new]
}

set context [list [list list #altered.Parties_List#] $page_title]

ad_form -name addedit \
    -form {
	{item_id:key}
	{-section "sec1" {legendtext "#altered.Main_Info#"} {fieldset {class legend}}}
	{code:text,optional
	    {label #altered.Code#}
	    {html {readonly ""}}
	}
	{title:text
	    {label #altered.Business_Name#}
	}
	{vat_number:text,optional
	    {label #altered.VAT_Number#}
	}
	{tax_code:text,optional
	    {label #altered.Tax_Code#}
	}
	{-section "sec2" {legendtext "#altered.Location_Info#"} {fieldset {class legend}}}
	{location_id:text(hidden),optional}
	{loc_name:text
	    {label #altered.Address_Name#}
	}
	{loc_street:text,optional
	    {label #altered.Street#}
	}
	{loc_number:text,optional
	    {label #altered.Street_Number#}
	}
	{loc_city:text,optional
	    {label #altered.City#}
	}
	{loc_country:text(select),optional
	    {label #acs-subsite.Country_Name#}
	    {options {{"" ""} [::xo::dc list_of_lists get_countries "
             select default_name, iso from countries"]}}
	    {value "[lindex [split [ad_conn locale] _] 1]"}
	}
	{loc_region:text,optional
	    {label #altered.Region#}
	}
	{loc_zone:text,optional
	    {label #altered.Zone#}
	}
	{loc_email:text,optional
	    {label #acs-subsite.Email#}
	}
	{loc_phone:text,optional
	    {label #altered.Phone#}
	}
	{-section ""}
    } -edit_request {
	foreach field {code title vat_number tax_code} {
	    set $field [$data set $field]
	}
	set location_id [$data get_main_location]
	if {$location_id ne ""} {
	    set loc [::xo::db::Class get_instance_from_db -id $location_id]
	    foreach field {country street region zone city number name email phone} {
		set loc_$field [$loc set $field]
	    }
	}
    } -on_submit {

        if {$loc_email ne "" && ![util_email_valid_p $loc_email]} {
            template::form::set_error addedit code #acs-templating.Invalid_email_format#
        }
	if {[::xo::dc 0or1row check "
           select 1 from [$class table_name]
            where code = :code
              and [$class id_column] <> :item_id"]} {
	    template::form::set_error addedit code #altered.Code_is_not_unique#
	}
        if {![template::form::is_valid addedit]} {
            break
        }

	foreach field {code title vat_number tax_code} {
	    $data set $field [set $field]
	}
	if {$location_id ne ""} {
	    set loc [::xo::db::Class get_instance_from_db -id $location_id]
	} else {
	    set loc [::alt::Location new]
	}
        foreach field {country street region zone city number name email phone} {
	    $loc set $field [set loc_$field]
	}
	if {$location_id ne ""} {
	    $loc save
	} else {
	    set location_id [$loc save_new]
	}
    } -new_data {
	::xo::dc transaction {
	    set party_id [$data save_new]
	    ::xo::dc dml save_location "
              insert into alt_party_locations (
                party_id, location_id, name, main_p
              ) values (:party_id, :location_id, :loc_name, true)"
	}
    } -edit_data {
	$data save
	if {[$data get_main_location] eq ""} {
	    set party_id [$data set party_id]
	    ::xo::dc dml save_location "
              insert into alt_party_locations (
                party_id, location_id, name, main_p
              ) values (:party_id, :location_id, :loc_name, true)"
	}
    } -after_submit {
	ad_returnredirect list
	ad_script_abort
    }
