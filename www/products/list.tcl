ad_page_contract {
    Products list
} {
    {rows_per_page:naturalnum 30}
    orderby:optional
    page:naturalnum,optional
}

set page_title [_ altered.Products_List]
set context [list $page_title]

set package_url [ad_conn package_url]

set this_url [export_vars -base [ad_conn url] -entire_form -no_empty]
set next_context [list [list $this_url $page_title]]

# Must be an existing acs_object class on the system.
::alt::Package initialize
set class "::alt::Product"

::Generic::List create list1 \
    -class $class \
    -package_id $package_id  \
    -rows_per_page $rows_per_page \
    -delete_url "../call?m=delete" \
    -edit_url "edit" \
    -create_url "edit" \
    -elements {
        attach {
	    link_url_col attach_url
	    display_template {<img src="/resources/acs-subsite/attach.png" width="16" height="16">}
	    link_html {title "#altered.View_attachments#"}
	    sub_class narrow
	}	
	code {
	    label "#altered.Code#"
	}
	name {
	    label "#altered.Name#"
	}
	description {
	    label "#altered.Description#"
	}
	um {
	    label "#altered.Unit_of_Measurement#"
	}
	price {
	    label "#altered.Price#"
	}	
	vat {
	    label "#altered.VAT#"
	}
    } -orderby {
	default_value name
	name {
	    label "#altered.Name#"
	    orderby_desc "name desc"
	    orderby_asc "name asc"
	}
    } -row_code {	
	if {$unity_id ne ""} {	    
	    set um [::xo::dc get_value get_um "
		select code from [::alt::Unity table_name]
		where unity_id = :unity_id"]
	}
	if {$vat_id ne ""} {	    
	    set vat [::xo::dc get_value get_vat "
		select code from [::alt::VAT table_name]
		where vat_id = :vat_id"]
	}

	set attach_url [export_vars -base "${package_url}attachments-list" {{object_id $product_id} {context $next_context}}]	
    }

list1 generate
