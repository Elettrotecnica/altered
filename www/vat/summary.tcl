ad_page_contract {
    Invoices list
} {
    year:naturalnum,optional
    month:naturalnum,optional

    orderby:optional
}

set page_title [_ altered.VAT_Summary]
set context [list $page_title]

set current_year [clock format [clock seconds] -format %Y]
set last_month [clock format [clock scan "- 1 month"] -format %m]

if {![info exists year]} {set year $current_year}
if {![info exists month]} {set month $last_month}

# creates filters form
set validated_p t
ad_form \
    -name filter \
    -edit_buttons [list [list "Go" go]] \
    -form {
	{month:integer,optional
	    {label "#acs-templating.Month#"}
	    {html {length 5 maxlength 2} }
	    {value $month}
	}
	{year:integer,optional
	    {label "#acs-templating.Year#"}
	    {html {length 5 maxlength 4} }
	    {value $year}
	}
    } -on_request {


    } -on_submit {

	set validated_p [template::form is_valid filter]
	if {!$validated_p} {
	    break
	}
    }

set from_date $year-$month-01
set to_date [clock format [clock add [clock scan $from_date] 1 month -1 day] -format %Y-%m-%d]

# prepare actions buttons
set actions {}

set bulk_actions {}

set line_actions {}

template::list::create \
    -name purchsummary \
    -multirow purchsummary \
    -actions $actions \
    -bulk_actions $bulk_actions \
    -bulk_action_method "post" \
    -elements {
	vat_name {
	    label "#altered.VAT#"
	}
	deductible_amount {
	    display_col deductible_amount_pretty
	    label "#altered.Deductible_Tax_Amount#"
	    html {align right}
	    aggregate "sum"
	}
	undeductible_amount {
	    display_col undeductible_amount_pretty
	    label "#altered.Undeductible_Tax_Amount#"
	    html {align right}
	    aggregate "sum"
	}
    } \
    -orderby {
        default_value "vat_name,asc"
        vat_name {
	    label "#altered.VAT#"
	    orderby_asc "v.name asc"
	    orderby_desc "v.name desc"
	}
    } \
    -filters {
	month {
	    hide_p 1
            where_clause {}
	}
	year {
	    hide_p 1
	    where_clause {}
	}
    }


if {$validated_p} {
    set extend_cols {
	deductible_amount_pretty
	undeductible_amount_pretty
    }

    set this_url [export_vars -base [ad_conn url] -entire_form -no_empty]
    set package_url [ad_conn package_url]

    db_multirow -extend $extend_cols purchsummary purc_multirow_query {} {
	set deductible_amount_pretty   [lc_numeric $deductible_amount]
	set undeductible_amount_pretty [lc_numeric $undeductible_amount]
    }

    # save current url vars for future reuse
    ad_set_client_property [ad_conn package_key] [ad_conn url] [export_vars -entire_form -no_empty]

} else {

    # erase session variables on errors
    ad_set_client_property [ad_conn package_key] [ad_conn url] ""

    # create a fake multirow
    template::multirow create purchsummary dummy
}


# prepare actions buttons
set actions {}

set bulk_actions {}

set line_actions {}

template::list::create \
    -name salesummary \
    -multirow salesummary \
    -actions $actions \
    -bulk_actions $bulk_actions \
    -bulk_action_method "post" \
    -elements {
	vat_name {
	    label "#altered.VAT#"
	}
	deductible_amount {
	    display_col deductible_amount_pretty
	    label "#altered.Deductible_Tax_Amount#"
	    html {align right}
	    aggregate "sum"
	}
	undeductible_amount {
	    display_col undeductible_amount_pretty
	    label "#altered.Undeductible_Tax_Amount#"
	    html {align right}
	    aggregate "sum"
	}
    } \
    -orderby {
        default_value "vat_name,asc"
        vat_name {
	    label "#altered.VAT#"
	    orderby_asc "v.name asc"
	    orderby_desc "v.name desc"
	}
    } \
    -filters {
	month {
	    hide_p 1
            where_clause {}
	}
	year {
	    hide_p 1
	    where_clause {}
	}
    }


if {$validated_p} {
    set extend_cols {
	deductible_amount_pretty
	undeductible_amount_pretty
    }

    set this_url [export_vars -base [ad_conn url] -entire_form -no_empty]
    set package_url [ad_conn package_url]

    db_multirow -extend $extend_cols salesummary sale_multirow_query {} {
	set deductible_amount_pretty   [lc_numeric $deductible_amount]
	set undeductible_amount_pretty [lc_numeric $undeductible_amount]
    }

    # save current url vars for future reuse
    ad_set_client_property [ad_conn package_key] [ad_conn url] [export_vars -entire_form -no_empty]

} else {

    # erase session variables on errors
    ad_set_client_property [ad_conn package_key] [ad_conn url] ""

    # create a fake multirow
    template::multirow create salesummary dummy
}
