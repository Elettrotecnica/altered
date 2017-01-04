ad_page_contract {
    Object deletion
} {
    item_id:naturalnum
    {return_url ..}
}

::xo::db::Class delete -id $item_id

ad_returnredirect $return_url
ad_script_abort
