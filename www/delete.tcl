ad_page_contract {
    Object deletion
} {
    item_id:naturalnum,multiple
    {return_url ..}
}

foreach id $item_id {
    ::xo::db::Class delete -id $id
}

ad_returnredirect $return_url
ad_script_abort
