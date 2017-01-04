ad_page_contract {
    Products list
} {
    {rows_per_page:naturalnum 30}
    orderby:optional
    page:naturalnum,optional
}

set page_title "#altered.Products_List#"
set context [list $page_title]

# Must be an existing acs_object class on the system.
::alt::Package initialize
set class "::alt::Product"

::Generic::List create list1 \
    -class $class \
    -package_id $package_id  \
    -rows_per_page $rows_per_page \
    -delete_url "../delete" \
    -edit_url "edit" \
    -create_url "edit" \
    -elements {
	code {
	    label "#altered.Code#"
	}
	name {
	    label "#altered.Name#"
	}
	description {
	    label "#altered.Description#"
	}
    } -orderby {
	default_value name
	name {
	    label "#altered.Name#"
	    orderby_desc "name desc"
	    orderby_asc "name asc"
	}
    } -row_code {
    }

list1 generate
