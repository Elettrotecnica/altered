ad_page_contract {
    Invoices list
} {
    {search_customer_name   ""}
    {search_customer_code   ""}
    {search_invoice_num     ""}
    {search_invoice_id      ""}
    {from_date              ""}
    {to_date                ""}
    {from_amount            ""}
    {to_amount              ""}
    {f_is_confirmed_p       ""}
    {f_is_paid_p            ""}

    {rows_per_page:naturalnum 30}
    orderby:optional
    page:naturalnum,optional
}

set page_title "#altered.Purchase_Invoices_List#"
set context [list $page_title]

# creates filters form
set validated_p t
ad_form \
    -name filter \
    -export {rows_per_page} \
    -edit_buttons [list [list "Go" go]] \
    -form {
	{search_invoice_num:text,optional
	    {label "#altered.Search_invoice_num#"}
	    {html {length 20} }
	    {value $search_invoice_num}
	}
	{search_customer_name:text,optional
	    {label "#altered.Search_party_name#"}
	    {html {length 20} }
	    {value $search_customer_name}
	}
	{search_customer_code:text,optional
	    {label "#altered.Search_party_code#"}
	    {html {length 20} }
	    {value $search_customer_code}
	}
	{from_date:date,optional
	    {label "#altered.From_date#"}
	    {html {length 20} }
	    {value $from_date}
	}
	{to_date:date,optional
	    {label "#altered.To_date#"}
	    {html {length 20} }
	    {value $to_date}
	}
	{from_amount:text,optional
	    {label "#altered.From_amount#"}
	    {html {length 20} }
	    {value $from_amount}
	}
	{to_amount:text,optional
	    {label "#altered.To_amount#"}
	    {html {length 20} }
	    {value $to_amount}
	}
	{f_is_confirmed_p:text(select),optional
	    {options {{[_ acs-kernel.common_All] ""} {[_ acs-kernel.common_Yes] t} {[_ acs-kernel.common_No] f}}}
	    {label "#altered.Approved__F#?"}
	    {value $f_is_confirmed_p}
	}
	{f_is_paid_p:text(select),optional
	    {options {{[_ acs-kernel.common_All] ""} {[_ acs-kernel.common_Yes] t} {[_ acs-kernel.common_No] f}}}
	    {label "#altered.Paid__F#?"}
	    {value $f_is_paid_p}
	}
    } -on_request {

	if {$from_date eq ""} {
            set from_date [clock format [clock scan "-12 months"] -format "%Y %m %d"]
        }

	set from_date_ansi [template::util::date::get_property ansi $from_date]

        if {$to_date eq ""} {
            set to_date [clock format [clock scan "12 months"] -format "%Y %m %d"]
        }

	set to_date_ansi [template::util::date::get_property ansi $to_date]

    } -on_submit {

	if {$from_amount ne ""} {
	    if {![string is double $from_amount]} {
		template::form::set_error filter from_amount \
		    [_ acs-templating.Invalid_decimal_number]
	    }
	}

	if {$to_amount ne ""} {
	    if {![string is double $to_amount]} {
		template::form::set_error filter to_amount \
		    [_ acs-templating.Invalid_decimal_number]
	    }
	}

	if {$from_date ne ""} {
	    set from_date_ansi [template::util::date::get_property ansi $from_date]
	} else {
	    set from_date_ansi ""
	}

	if {$to_date ne ""} {
	    set to_date_ansi [template::util::date::get_property ansi $to_date]
	} else {
	    set to_date_ansi ""
	}

	set validated_p [template::form is_valid filter]
	if {!$validated_p} {
	    break
	}
    }

# prepare actions buttons
set actions {
    "#altered.New_Invoice__Short#" edit "#altered.New_Invoice__Long#"
}

set bulk_actions {}

set line_actions {}

if {$validated_p} {
    set page_query_name paginator
} else {
    set page_query_name dummy_paginator
    template::multirow create invoices dummy
}

template::list::create \
    -name invoices \
    -multirow invoices \
    -actions $actions \
    -bulk_actions $bulk_actions \
    -key invoice_id \
    -bulk_action_method "post" \
    -page_flush_p t \
    -page_size $rows_per_page \
    -page_groupsize 10 \
    -page_query_name $page_query_name \
    -elements {
	edit {
	    link_url_col edit_url
	    display_template {<img src="/resources/acs-subsite/Edit16.gif" width="16" height="16" border="0">}
	    link_html {title "#altered.Edit_Invoice#"}
	    sub_class narrow
	}
        invoice_num {
	    label "#altered.Invoice_Num#"
	    link_url_col lines_url
	    link_html {title "#altered.Go_to_invoice_lines#"}
	}
	date {
	    label "#acs-datetime.Date#"
	    display_col date_pretty
	}
	party_name {
	    label "#altered.Party_Name#"
	    link_url_col party_url
	    link_html {title "#altered.Go_to_party#"}
	}
	amount {
	    display_col amount_pretty
	    label "#altered.Amount#"
	    html {align right}
	    aggregate "sum"
	}
	paid_amount {
	    display_col paid_amount_pretty
	    link_url_col payments_url
	    label "#altered.Paid_Amount#"
	    html {align right}
	    aggregate "sum"
	}
	confirmed_p {
	    label "#altered.Approved__F#"
	    link_url_col approve_reset_url
	    link_html {title "[_ altered.Confirm-Reset]"}
	    html {align center}
	}
	is_paid_p {
	    label "#altered.Completely_Paid#"
	    html {align center}
	}
	delete {
	    link_url_col delete_url
	    link_html {title "#altered.Delete_this_invoice#" class "confirm"}
	    display_template {<img src="/resources/acs-subsite/Delete16.gif" width="16" height="16" border="0">}
	    sub_class narrow
	}
    } \
    -orderby {
        default_value "invoice_date,desc"
        invoice_date {
	    label "#acs-datetime.Date#"
	    orderby_asc "date asc, invoice_num asc"
	    orderby_desc "date desc, invoice_num desc"
	}
        invoice_num {
	    label "#altered.Invoice_Num#"
	    orderby_asc "invoice_num asc"
	    orderby_desc "invoice_num desc"
	}
        customer_name {
	    label "#altered.Party_Name#"
	    orderby_asc "party_name asc, date asc, invoice_num asc"
	    orderby_asc "party_name desc, date desc, invoice_num desc"
	}
    } \
    -filters {
	search_invoice_num {
	    hide_p 1
            where_clause {(:search_invoice_num is null or upper(invoice_num) like '%' || upper(:search_invoice_num) || '%')}
	}
	search_invoice_id {
	    hide_p 1
            where_clause {(:search_invoice_id is null or invoice_id = :search_invoice_id)}
	}
	search_customer_name {
	    hide_p 1
            where_clause {(:search_customer_name is null or upper(party_name) like '%' || upper(:search_customer_name) || '%')}
	}
	search_customer_code {
	    hide_p 1
            where_clause {(:search_customer_code is null or upper(party_code) like '%' || upper(:search_customer_code) || '%')}
	}
        from_date {
            hide_p 1
            where_clause {(:from_date_ansi is null or date >= :from_date_ansi)}
        }
        to_date {
            hide_p 1
            where_clause {(:to_date_ansi is null or date <= :to_date_ansi)}
        }
	from_amount {
	    hide_p 1
	    where_clause {(:from_amount is null or amount >= :from_amount)}
	}
	to_amount {
	    hide_p 1
	    where_clause {(:to_amount is null or amount <= :to_amount)}
	}
        f_is_confirmed_p {
            hide_p 1
	    where_clause {(:f_is_confirmed_p is null or confirmed_p = :f_is_confirmed_p)}
        }
        f_is_paid_p {
            hide_p 1
	    where_clause {(:f_is_paid_p is null or (amount = paid_amount) = :f_is_paid_p)}
        }
        rows_per_page {
	    label "#altered.Rows_per_page#"
  	    values {{10 10} {30 30} {100 100} {"#acs-kernel.common_All#" 9999999}}
	    where_clause {1 = 1}
            default_value 30
        }
    }


if {$validated_p} {
    set extend_cols {
	edit_url
	lines_url
	party_url
	approve_reset_url
	delete_url
	paid_amount_pretty
	payments_url
	amount_pretty
	date_pretty
	is_paid_p
    }

    set this_url [export_vars -base [ad_conn url] -entire_form -no_empty]
    set package_url [ad_conn package_url]

    db_multirow -extend $extend_cols invoices multirow_query {} {
	set is_paid_p [expr {$amount != 0 && $amount == $paid_amount ? [_ acs-kernel.common_Yes] : [_ acs-kernel.common_No]}]

	set edit_url   [export_vars -base "edit" {{item_id $invoice_id}}]
	set lines_url  [export_vars -base "lines" {invoice_id}]
	set party_url  [export_vars -base "${package_url}parties/edit" {{item_id $party_id}}]

	if {$confirmed_p} {
	    set approve_reset_url [export_vars -base "${package_url}call" {{m reset} {item_id $invoice_id} {return_url $this_url}}]
	} else {
	    set approve_reset_url [export_vars -base "${package_url}call" {{m confirm} {item_id $invoice_id} {return_url $this_url}}]
	}

	set delete_url [export_vars -base "${package_url}call" {{m delete} {item_id $invoice_id} {return_url $this_url}}]

	set payments_url [export_vars -base "${package_url}payment-dates/list" {{document_id $invoice_id} {return_url $this_url}}]

	set date_pretty [lc_time_fmt $date %x]
	set amount_pretty      [lc_numeric $amount]
	set paid_amount_pretty [lc_numeric $paid_amount]

	set confirmed_p [expr {$confirmed_p ? [_ acs-kernel.common_Yes] : [_ acs-kernel.common_No]}]
    }

    # save current url vars for future reuse
    ad_set_client_property [ad_conn package_key] [ad_conn url] [export_vars -entire_form -no_empty]

} else {

    # erase session variables on errors
    ad_set_client_property [ad_conn package_key] [ad_conn url] ""

    # create a fake multirow
    template::multirow create invoices dummy
}

template::add_confirm_handler \
    -message [_ altered.Are_you_sure_you_want_to_delete?] \
    -CSSclass confirm
