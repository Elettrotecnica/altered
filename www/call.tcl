ad_page_contract {
    Call method on object
} {
    item_id:naturalnum
    m
    {return_url ..}
}

if {[::xo::db::Class exists_in_db -id $item_id]} {
    set o [::xo::db::Class get_instance_from_db -id $item_id]
    ::xo::dc transaction {$o $m}
}

ad_returnredirect $return_url
ad_script_abort
