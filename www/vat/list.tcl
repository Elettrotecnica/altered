ad_page_contract {
    VATs list
} {
    {rows_per_page:naturalnum 30}
    orderby:optional
    page:naturalnum,optional
}

set page_title "#altered.VATs_List#"
set context [list $page_title]

# Must be an existing acs_object class on the system.
::alt::Package initialize
set class "::alt::VAT"

::Generic::List create list1 \
    -class $class \
    -package_id $package_id  \
    -rows_per_page $rows_per_page \
    -delete_url "../call?m=delete" \
    -edit_url "edit" \
    -create_url "edit" \
    -elements {
	code {
	    label "#altered.Code#"
	}
	name {
	    label "#altered.Name#"
	}
	rate {
	    label "#altered.Rate#"
	}	
	undeductible_rate {
	    label "#altered.Undeductible_Rate#"
	}	
    } -orderby {
	default_value name
	name {
	    label "#altered.Name#"
	    orderby_desc "name desc"
	    orderby_asc "name asc"
	}
    } -row_code {
	set rate              [lc_numeric $rate]%
	set undeductible_rate [lc_numeric $undeductible_rate]%	
    }

list1 generate
