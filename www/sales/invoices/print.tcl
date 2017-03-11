ad_page_contract {
    Print object
} {
    invoice_id:naturalnum
}

::xo::db::Class get_instance_from_db -id $invoice_id
$invoice_id print
