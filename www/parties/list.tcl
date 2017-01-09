ad_page_contract {
    Parties list
} {
    {rows_per_page:naturalnum 30}
    orderby:optional
    page:naturalnum,optional
}

set page_title "#altered.Parties_List#"
set context [list $page_title]

# Must be an existing acs_object class on the system.
::alt::Package initialize
set class "::alt::Party"

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
	title {
	    label "#altered.Business_Name#"
	}
	vat_number {
	    label "#altered.VAT_Number#"
	}
	tax_code {
	    label "#altered.Tax_Code#"
	}
	loc_street {
	    label "#altered.Street#"
	}
	loc_number {
	    label "#altered.Street_Number#"
	}
	loc_city {
	    label "#altered.City#"
	}
	loc_country {
	    label "#acs-subsite.Country_Name#"
	}	
    } -orderby [subst {
	default_value title
	title {
	    label "#altered.Business_Name#"
	    orderby_desc "[$class table_name].title desc"
	    orderby_asc "[$class table_name].title asc"
	}
    }] -row_code {
	set location_id [::xo::dc get_value location "
         select location_id from alt_party_locations
          where party_id = :party_id and main_p" ""]
	if {$location_id ne ""} {
	    set l [::xo::db::Class get_instance_from_db -id $location_id]
	    foreach field {street region zone city number} {
		set loc_$field [$l set $field]
	    }
	    set country [$l set country]
	    if {$country ne ""} {
		set loc_country [::xo::dc get_value country "
                  select default_name from countries 
                   where iso = :country"]
	    }
	}
    }

list1 generate
