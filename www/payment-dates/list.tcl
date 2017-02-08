ad_page_contract {
    Products list
} {
    {rows_per_page:naturalnum 30}
    orderby:optional
    page:naturalnum,optional
    document_id:naturalnum
    {return_url ""}
}

set page_title "#altered.Payment_Dates_List#"
set context [list $page_title]

set doc [::xo::db::Class get_instance_from_db -id $document_id]

# Must be an existing acs_object class on the system.
::alt::Package initialize
set class "::alt::PaymentDate"

set edit_url [export_vars -base "edit" -no_empty {document_id return_url}]

set paid_p [::xo::dc get_value paid_amount {
    select amount - paid_amount = 0 from alt_document_amountsi
    where document_id = :document_id}]
set no_create_p $paid_p

::Generic::List create list1 \
    -class $class \
    -package_id $package_id  \
    -rows_per_page $rows_per_page \
    -edit_url $edit_url \
    -create_url $edit_url \
    -no_create_p $no_create_p \
    -elements {
	due_date {
	    label "#altered.Due_Date#"
	}
	closing_date {
	    label "#altered.Closing_Date#"
	}
	amount {
	    label "#altered.Amount#"
	}
	paid_amount {
	    label "#altered.Paid_Amount#"
	}
    } -orderby {
	default_value due_date,asc
	due_date {
	    label "#altered.Due_Date#"
	    orderby_desc "due_date desc"
	    orderby_asc "due_date asc"
	}
    } -row_code {
	set due_date     [lc_time_fmt $due_date %x]
	set closing_date [lc_time_fmt $closing_date %x]
	set amount       [lc_numeric $amount]
	
	set paid_amount  [::xo::dc get_value paid_amount {
	    select paid_amount from alt_document_amountsi
	    where document_id = :document_id}]
	set paid_amount  [lc_numeric $paid_amount]

    } -filters [subst {
        return_url { hide_p 1 }
	document_id {
	    hide_p 1
            where_clause { document_id = $document_id }
	}
    }]

list1 generate
