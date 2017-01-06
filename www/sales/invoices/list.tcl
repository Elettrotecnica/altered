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
	print_with_mail {
	    link_url_col print_with_mail_url
	    display_template {<img src="/resources/mis-base/printer_mail.gif" border="0">}
	    link_html {title "Stampa fattura con prezzo e invia al cliente"}
	    sub_class narrow
	}
        invoice_num {
	    label "N. fattura"
	    link_url_col lines_url
	    link_html {title "Dettaglio fattura/nota di credito"}
	}
	invoice_date {
	    label "Dt. fattura"
	    display_col invoice_date_pretty
	    link_url_col pay_url
	    link_html {title "Modifica Cond. di Pagamento"}
	}
	customer_name {
	    label "Ragione sociale"
	    link_url_col cust_url
	    link_html {title "Visualizza/Modifica cliente"}
	}
	invoice_amount {
	    display_col invoice_amount_pretty
	    label "Totale Fattura"
	    html {align right}
	    aggregate "sum"
	}
	paid_amount {
	    display_col invoice_amount_pretty
	    label "Totale Fattura"
	    html {align right}
	    aggregate "sum"
	}
	is_confirmed_p_pretty {
	    label "Conf."
	    link_url_col approve_reset_url
	    link_html {title "Conferma/Ripristina fattura/nota di credito"}
	    html {align center}
	}
	is_paid_p {
	    label "Pag."
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
	    label "Data"
	    orderby_asc "invoice_date, invoice_num"
	    orderby_desc "invoice_date desc, invoice_num desc"
	}
        invoice_num {
	    label "N. fattura"
	    orderby_asc "invoice_num"
	    orderby_desc "invoice_num desc"
	}
        customer_name {
	    label "Cliente"
	    orderby_asc "c.upper_title, invoice_date, invoice_num"
	    orderby_desc "c.upper_title desc, invoice_date, invoice_num"
	}
    } \
    -filters {
	search_invoice_num {
	    hide_p 1
            where_clause {[ah::search_clause_f -search_word $search_invoice_num -search_field i.invoice_num]}
	}
	search_invoice_id {
	    hide_p 1
            where_clause {sale_invoice_id = :search_invoice_id}
	}
	search_customer_name {
	    hide_p 1
            where_clause {[ah::search_clause_f -search_word $search_customer_name -search_field c.upper_title]}
	}
        search_rep_id {
	    hide_p 1
	    where_clause {i.sale_rep_id = :search_rep_id}
        }
	search_customer_code {
	    hide_p 1
            where_clause {[ah::search_clause_f -search_word $search_customer_code -search_field c.party_code]}
	}
	search_abi {
	    hide_p 1
            where_clause {:search_abi = b.abi}
	}
        from_date {
            hide_p 1
            where_clause {i.invoice_date >= :from_date_ansi}
        }
        to_date {
            hide_p 1
            where_clause {i.invoice_date <= :to_date_ansi}
        }
        from_date_ansi {hide_p 1}
        to_date_ansi {hide_p 1}
	from_amount_pretty {
	    hide_p 1
	    where_clause {(:from_amount is null or i.invoice_amount >= :from_amount)}
	}
	from_amount {hide_p 1}
	to_amount_pretty {
	    hide_p 1
	    where_clause {(:to_amount is null or i.invoice_amount <= :to_amount)}
	}
        to_amount {hide_p 1}
        f_invoice_type_id {
	    hide_p 1
	    where_clause {i.invoice_type_id = :f_invoice_type_id}
        }
	search_counter_section {
	    hide_p 1
            where_clause {(:search_counter_section is null or :search_counter_section = (
		select counter_section from mis_counters where counter_id = (
		    select counter_id from mis_invoice_types where invoice_type_id = i.invoice_type_id)))}
	}
        f_is_confirmed_p {
            hide_p 1
	    where_clause {i.is_confirmed_p = :f_is_confirmed_p}
        }
        search_carrier_id {
            hide_p 1
            where_clause {exists (select 1 from mis_delivery_notes 
                                    where carrier_id = :search_carrier_id 
                                      and sale_invoice_id = i.sale_invoice_id)}
        }
	f_payment_type_id {
	    hide_p 1
	    where_clause {(select payment_type_id from mis_payments where payment_id = i.payment_id) = :f_payment_type_id}
	}
	f_iva_id {
	    hide_p 1
	    where_clause {exists (select 1 from mis_sale_invoice_lines where sale_invoice_id = i.sale_invoice_id and iva_id = :f_iva_id)}
	}
        f_is_paid_p {
            hide_p 1
	    where_clause {not exists (select 1 from mis_sale_paydates 
	      where invoice_id = i.sale_invoice_id and not is_closed_p) = :f_is_paid_p}
        }
	f_has_invoice_mail_p {
	    hide_p 1
	    where_clause {(exists (select 1 
                                     from mis_invoice_mail 
                                    where sale_invoice_id = i.sale_invoice_id 
                                      and sent       is not null limit 1)) = :f_has_invoice_mail_p}
	}
	f_has_attachment_p {
	    hide_p 1
	    where_clause {(:f_has_attachment_p is null or (exists (
	      select 1 from attachments a, fs_objects o
	      where a.object_id = i.sale_invoice_id
		and a.item_id = o.object_id
		and name not like '%invoice-' || i.sale_invoice_id || '.pdf'
		  limit 1)) = :f_has_attachment_p)}
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
	print_url 
	attach_url
	save_url
	attach_class
	print_with_prices_url 
	print_with_mail_url 
	reprint_url 
	lines_url 
	pay_url 
	cust_url 
	approve_reset_url 
	delete_url 
	is_confirmed_p_pretty
	delivery_codes 
	clone_url
	sum_amount
	invoice_amount_pretty
        ack_url
    }
    
    db_multirow -extend $extend_cols invoices query "
	select i.*,
               
        from alt_sale_invoicesi i
	     alt_parties c
        where i.invoice_type_id = t.invoice_type_id
	  and c.party_id = i.customer_id
        [template::list::page_where_clause -name invoices -key i.sale_invoice_id -and]
        [template::list::orderby_clause -name invoices -orderby]
    " { 
        # ottengo i numeri di DDT collegati alla fattura
	foreach delivery_code [db_list query "       
	  select delivery_code from mis_delivery_notes
	    where sale_invoice_id = :sale_invoice_id"] {
	    set delivery_url [export_vars -base "/mis-sales/deliveries/list" {{search_delivery_code $delivery_code}}]
	    lappend delivery_codes "<a href='$delivery_url'>$delivery_code</a>"
	}
	# rimuovo le parentesi graffe che delimitano la lista
	set delivery_codes [join $delivery_codes " "]

	set is_paid_p [ad_decode $is_paid_p t Si f No No]
	
	set clone_url   [export_vars -base "clone" {sale_invoice_id}]
	set edit_url    [export_vars -base "add-edit" {sale_invoice_id customer_id}]
	set reprint_url [export_vars -base "reprint" {sale_invoice_id}]
	set lines_url   [export_vars -base "lines" {sale_invoice_id}]
	set pay_url     [export_vars -base "add-edit-pay" {sale_invoice_id}]
	set delete_url  [export_vars -base "delete" {sale_invoice_id}]
	set cust_url    [export_vars -base "/mis-base/parties/add-edit" {{item_id $customer_id} {is_customer_p t}}]
	set attach_url  [export_vars -base "/mis-base/attachments" {{object_id $sale_invoice_id} {context $next_context}}]
	set save_url    [export_vars -base "/mis-purc/prices/save-into-pricelist" {{item_id $sale_invoice_id} {return_url $this_url}}]

	if {$dot_matrix_printer_p} {
	    set print_url             [export_vars -base "print-mod" {sale_invoice_id}]
	    set print_with_prices_url [export_vars -base "print-no-prices" {sale_invoice_id}]
	    set print_with_mail_url   [export_vars -base "print-with-mail" {sale_invoice_id}]
	} else {
	    set print_url             [export_vars -base "print-no-prices" {sale_invoice_id}]
	    set print_with_prices_url [export_vars -base "print-with-prices" {sale_invoice_id}]
	    set print_with_mail_url   [export_vars -base "print-with-mail" {sale_invoice_id}]
	}
	
	# Verifico se ho degli allegati.
	if {$has_attachments_p} {
	    set attach_class "has-attachment"
	} else {
	    set attach_class ""
	}

	if {$ack_sent_p} {
	    set ack_sent_p Si
	    set ack_url [export_vars -base "/mis-base/mail/mail-list" {object_id {prev_url $this_url} {prev_url_title $page_title}}]
	} else {
	    set ack_sent_p No
	    set ack_url ""
	}
	
	if {$is_confirmed_p} {
	    set approve_reset_url [export_vars -base "reset" {sale_invoice_id}]
	} else {
	    set approve_reset_url [export_vars -base "approve" {sale_invoice_id}]
	}

	set delete_url [export_vars -base "delete" {sale_invoice_id}]
	set cust_url   [export_vars -base "/mis-base/parties/add-edit" {{item_id $customer_id} {is_customer_p t}}]
	
	if {$is_invoice ne t} {
	    set invoice_amount [expr {$invoice_amount * -1.00}]
	}
        set sum_amount $invoice_amount
	set invoice_amount_pretty [ah::edit_num $invoice_amount 2]
	
	set is_confirmed_p_pretty [ad_decode $is_confirmed_p t Si f No No]
    }
    
    # save current url vars for future reuse
    ad_set_client_property mis-sales invoices/list [export_vars -entire_form -no_empty]
    
} else {
    
    # In caso di errore azzero le variabili di sessione salvate.
    ad_set_client_property mis-sales invoices/list ""
    
    # creo una multirow fittizia 
    template::multirow create invoices dummy
}
