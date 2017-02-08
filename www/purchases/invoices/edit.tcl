ad_page_contract {
    Invoice Add/Edit
} {
    item_id:naturalnum,optional
}

set package_key [ad_conn package_key]
template::head::add_javascript -src  "/resources/$package_key/javascript/jquery-ui/js/jquery-1.8.0.min.js" -order 0
template::head::add_javascript -src  "/resources/$package_key/javascript/jquery-ui/js/jquery-ui-1.8.23.custom.min.js" -order 1
template::head::add_css        -href "/resources/$package_key/javascript/jquery-ui/development-bundle/themes/base/jquery.ui.all.css"
template::head::add_javascript -src "/resources/$package_key/javascript/ah-util.js" -order 2

# Must be an existing acs_object class on the system.
::alt::Package initialize
set class "::alt::PurchaseInvoice"

if {[info exists item_id] && [::xo::db::Class exists_in_db -id $item_id]} {
    set page_title #altered.Edit_Purchase_Invoice#
    set data [::xo::db::Class get_instance_from_db -id $item_id]
} else {
    set page_title #altered.Create_Purchase_Invoice#
    set data [$class new]
}

set context [list [list list #altered.Purchase_Invoices_List#] $page_title]

set form_id addedit

ad_form -name $form_id \
    -form {
	{item_id:key}
	{-section "sec1" {legendtext "#altered.Main_Info#"} {fieldset {class legend}}}
	{invoice_num:text,optional
	    {label #altered.Invoice_Num#}
	    {html {readonly ""}}
	}
	{date:date
	    {label #acs-datetime.Date#}
	}
	{invoice_year:integer
	    {label #altered.Invoice_Year#}
	}
	{party_id:integer
	    {label #altered.Party#}
	}
	{description:text,optional
	    {label #altered.Description#}
	}
	{-section "sec2" {legendtext "#altered.Location_Info#"} {fieldset {class legend}}}
	{location_id:text(hidden),optional}
	{loc_name:text,optional
	    {label #altered.Address_Name#}
	    {html {readonly ""}}
	}
	{loc_street:text,optional
	    {label #altered.Street#}
	    {html {readonly ""}}
	}
	{loc_number:text,optional
	    {label #altered.Street_Number#}
	    {html {readonly ""}}
	}
	{loc_city:text,optional
	    {label #altered.City#}
	    {html {readonly ""}}
	}
	{loc_country:text(select),optional
	    {label #acs-subsite.Country_Name#}
	    {options {{"" ""} [::xo::dc list_of_lists get_countries "
             select default_name, iso from countries"]}}
	    {html {readonly ""}}
	}
	{loc_region:text,optional
	    {label #altered.Region#}
	    {html {readonly ""}}
	}
	{loc_zone:text,optional
	    {label #altered.Zone#}
	    {html {readonly ""}}
	}
	{-section ""}
    } -new_request {

	set date [clock format [clock seconds] -format "%Y %m %d"]
	set invoice_year [lindex $date 0]
	
    } -edit_request {
	foreach field {description party_id invoice_num location_id invoice_year date} {
	    set $field [$data set $field]
	}
	if {$date ne ""} {
	    set date [split [lindex $date 0] -]
	}
	if {$location_id eq ""} {
	    set party [::xo::db::Class get_instance_from_db -id $party_id]
	    set location_id [$party get_main_location]
	}
	if {$location_id ne ""} {
	    set loc [::xo::db::Class get_instance_from_db -id $location_id]
	    foreach field {country street region zone city number name} {
		set loc_$field [$loc set $field]
	    }
	}
    } -on_refresh {
	set party_id [template::element::get_value $form_id party_id]
	if {$party_id ne ""} {
	    set party [::xo::db::Class get_instance_from_db -id $party_id]
	    set location_id [$party get_main_location]
	} else {
	    set location_id [template::element::get_value $form_id location_id]
	}
	if {$location_id ne ""} {
	    set loc [::xo::db::Class get_instance_from_db -id $location_id]
	    foreach field {country street region zone city number name} {
		template::element::set_value $form_id loc_$field [$loc set $field]
	    }
	}
    } -on_submit {
	if {[::xo::dc 0or1row check "
           select 1 from [$class table_name]
            where invoice_num  = :invoice_num
              and invoice_year = :invoice_year
              and [$class id_column] <> :item_id"]} {
	    template::form::set_error addedit code #altered.Code_is_not_unique#
	    break
	}
	if {$date ne ""} {
	    set date [template::util::date::get_property ansi $date]
	}
	foreach field {description party_id invoice_num location_id invoice_year date} {
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

template::add_body_script -type text/javascript -script {
    $(function() {
	var comboFields = [['party_id', '../../ac-ws/parties']];
	ahAutocomplete(comboFields);

	var e = document.getElementById('addedit').elements.namedItem('party_id').previousElementSibling;
	if (e !== null) {
	    e.addEventListener('blur', function (event) {
		if (this.value != '') {
		    var form = document.getElementById('addedit');
		    form.__refreshing_p.value='1';
		    form.submit();
		}
	    }, false);
	}
    });
}
