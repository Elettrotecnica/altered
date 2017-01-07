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

set page_title "#altered.Sale_Invoices_List#"
set context [list $page_title]

# Must be an existing acs_object class on the system.
::alt::Package initialize
set class "::alt::SaleInvoice"


# creates filters form
ad_form \
    -name filter \
    -export {rows_per_page} \
    -edit_buttons [list [list "Go" go]] \
    -form {
	{search_invoice_num:text,optional
	    {label {Cerca N. Fattura}}
	    {html {length 20} }
	    {value $search_invoice_num}
	}
	{search_customer_name:text,optional
	    {label {Cerca ragione sociale }}
	    {html {length 20} }
	    {value $search_customer_name}
	}
	{search_customer_code:text,optional
	    {label {Cerca codice soggetto }}
	    {html {length 20} }
	    {value $search_customer_code}
	}
	{from_date:date,optional
	    {label {Da data}}
	    {html {length 20} }
	    {value $from_date}
	}
	{to_date:date,optional
	    {label {A data}}
	    {html {length 20} }
	    {value $to_date}
	}
	{from_amount:text,optional
	    {label {Da importo}}
	    {html {length 20} }
	    {value $from_amount}
	}
	{to_amount:text,optional
	    {label {A importo}}
	    {html {length 20} }
	    {value $to_amount}
	}
	{f_is_confirmed_p:text(select),optional
	    {options {{Tutti ""} {Si t} {No f}}}
	    {label "Confermata?"}
	    {value $f_is_confirmed_p}
	}
	{f_is_paid_p:text(select),optional
	    {options {{Tutti ""} {Si t} {No f}}}
	    {label "Pagata?"}
	    {value $f_is_paid_p}
	}
    } -on_request {

	if {$from_date eq ""} {
            set from_date [clock format [clock scan "-12 months"] -format %Y-%m-%d]
        }

        if {$to_date eq ""} {
            set to_date [clock format [clock scan "12 months"] -format %Y-%m-%d]
        }

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

	if {[template::form is_valid filter]} {
	    break
	}
    }

# prepare actions buttons
set actions {
    "#altered.New_Invoice__Short#" edit "#altered.New_Invoice__Long#"
}

set blulk_actions {}
    # set bulk_actions {
    # 	"Stampa senza prezzo"  print-no-prices    "Stampa le fatture selezionate"
    # 	"Stampa con prezzo"    print-with-prices  "Stampa le fatture selezionate con i prezzi"
    # 	"Stampa e invio email" print-with-mail    "Stampa le fatture selezionate con i prezzi e invia una copia al cliente"
    # 	"Stampa per consegna"  print-to-deliver  "Stampa le DDT selezionate in doppia copia e ordinate in base al percorso"
    # 	"Conferma"             approve            "Conferma le fatture selezionate"
    # 	"Cedi credito"         factor             "Cedi il credito delle fatture selezionate"
    # 	"Modif. Agente"        sale-rep-change    "Modifica Agente sulle fatture selezionate"
    # }

set line_actions {}

if {[template::form is_valid filter]} {
    set page_query_name paginator
} else {
    set page_query_name dummy_paginator
    template::multirow create invoices dummy
}

	# attach {
	#     link_url_col attach_url
	#     display_template {<img src="/resources/mis-base/att_new.gif" width="16" height="16" class="@invoices.attach_class@">}
	#     link_html {title "Gestisci allegati"}
	#     sub_class narrow
	# }
	# print {
	#     link_url_col print_url
	#     display_template {<img src="/resources/mis-base/printer.gif" border="0">}
	#     link_html {title "Stampa fattura senza prezzo"}
	#     sub_class narrow
	# }
	# print_with_prices {
	#     link_url_col print_with_prices_url
	#     display_template {<img src="/resources/mis-base/printer_prices.gif" border="0">}
	#     link_html {title "Stampa fattura con prezzo"}
	#     sub_class narrow
        # }
	# print_with_mail {
	#     link_url_col print_with_mail_url
	#     display_template {<img src="/resources/mis-base/printer_mail.gif" border="0">}
	#     link_html {title "Stampa fattura con prezzo e invia al cliente"}
	#     sub_class narrow
	# }
	# actions {
	#     label "Azioni"
	#     display_template $line_actions
	# }



template::list::create \
    -name invoices \
    -multirow invoices \
    -actions $actions \
    -bulk_actions $bulk_actions \
    -key sale_invoice_id \
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
	invoice_date {
	    label "#altered.Invoice_Date#"
	    display_col invoice_date_pretty
	}
	customer_name {
	    label "#altered.Customer_Name#"
	    link_url_col customer_url
	    link_html {title "#altered.Go_to_party#"}
	}
	invoice_amount {
	    display_col invoice_amount_pretty
	    label "#altered.Invoice_Amount#"
	    html {align right}
	    aggregate "sum"
	}
	paid_amount {
	    display_col paid_amount_pretty
	    label "#altered.Paid_Amount#"
	    html {align right}
	    aggregate "sum"
	}
	is_confirmed_p {
	    label "#altered.Approved#"
	    link_url_col approve_reset_url
	    link_html {title "#altered.Confirm/Reset#"}
	    html {align center}
	}
	is_paid_p {
	    label "#altered.Completely_Paid#"
	    html {align center}
	}
	delete {
	    link_url_col delete_url
	    link_html {title "#altered.Delete_this_invoice#" class "confirm" data-msg "#altered.Confirm_delete?#"}
	    display_template {<img src="/resources/acs-subsite/Delete16.gif" width="16" height="16" border="0">}
	    sub_class narrow
	}
    } \
    -orderby {
        default_value "invoice_date,desc"
        invoice_date {
	    label "#altered.Invoice_Date#"
	    orderby_asc "i.date asc, i.code asc"
	    orderby_desc "i.date desc, i.code desc"
	}
        invoice_num {
	    label "#altered.Invoice_Num#"
	    orderby_asc "i.code asc"
	    orderby_desc "i.code desc"
	}
        customer_name {
	    label "#altered.Customer_Name#"
	    orderby_asc "c.title asc, i.date asc, i.code asc"
	    orderby_asc "c.title desc, i.date desc, i.code desc"
	}
    } \
    -filters {
	search_invoice_num {
	    hide_p 1
            where_clause {(:search_invoice_num is null or upper(i.code) like '%' || upper(:search_invoice_num) || '%')}
	}
	search_invoice_id {
	    hide_p 1
            where_clause {(:search_invoice_id is null or i.document_id = :search_invoice_id)}
	}
	search_customer_name {
	    hide_p 1
            where_clause {(:search_customer_name is null or upper(c.title) like '%' || upper(:search_customer_name) || '%')}	    
	}
	search_customer_code {
	    hide_p 1
            where_clause {(:search_customer_code is null or upper(c.code) like '%' || upper(:search_customer_code) || '%')}	    	    
	}
        from_date {
            hide_p 1
            where_clause {(:from_date is null or i.invoice_date >= :from_date)}
        }
        to_date {
            hide_p 1
            where_clause {(:to_date is null or i.invoice_date <= :to_date)}	    
        }
	from_amount {
	    hide_p 1
	    where_clause {(:from_amount is null or i.invoice_amount >= :from_amount)}
	}
	to_amount {
	    hide_p 1
	    where_clause {(:to_amount is null or i.invoice_amount <= :to_amount)}
	}
        f_is_confirmed_p {
            hide_p 1
	    where_clause {(:f_is_confirmed_p is not null or i.confirmed_p = :f_is_confirmed_p)}
        }
        f_is_paid_p {
            hide_p 1
	    where_clause {(:f_is_paid_p is not null or (i.amount = i.paid_amount) = :f_is_paid_p)}
        }
        rows_per_page {
	    label "Righe per pagina"
  	    values {{10 10} {30 30} {100 100} {Tutte 9999999}}
	    where_clause {1 = 1}
            default_value 30
        }
    }


# eseguo la query solo in assenza di errori nei filtri del form
if {![info exists errnum]} {
    set extend_cols {
	edit_url
	lines_url
	customer_url
	approve_reset_url
	delete_url
	paid_amount_pretty
	invoice_amount_pretty
    }

    db_multirow -extend $extend_cols invoices query "
	select i.*,
               c.code as customer_code,
               c.title as customer_name
        from alt_sale_invoicesi i,
	     alt_parties c
        where c.party_id = i.party_id
        [template::list::page_where_clause -name invoices -key i.document_id -and]
        [template::list::orderby_clause -name invoices -orderby]
    " {
	set is_paid_p [expr {$amount == $paid_amount ? [_ acs-kernel.common_Yes] : [_ acs-kernel.common_No]}]

	set edit_url     [export_vars -base "edit" {document_id}]
	set lines_url    [export_vars -base "lines" {document_id}]
	set delete_url   [export_vars -base "delete" {document_id}]
	set customer_url [export_vars -base "[ad_conn package_key]/parties/edit" {party_id}]

	if {$confirmed_p} {
	    set approve_reset_url [export_vars -base "reset" {document_id}]
	} else {
	    set approve_reset_url [export_vars -base "approve" {document_id}]
	}

	set delete_url [export_vars -base "[ad_conn package_key]/delete" {{item_id $document_id}}]

	set amount_pretty      [lc_numeric $amount]
	set paid_amount_pretty [lc_numeric $paid_amount]	

	set is_confirmed_p [expr {$is_confirmed_p ? [_ acs-kernel.common_Yes] : [_ acs-kernel.common_No]}]
    }

    # save current url vars for future reuse
    ad_set_client_property [ad_conn package_key] [ad_conn url] [export_vars -entire_form -no_empty]

} else {

    # In caso di errore azzero le variabili di sessione salvate.
    ad_set_client_property [ad_conn package_key] [ad_conn url] ""

    # creo una multirow fittizia
    template::multirow create invoices dummy
}
