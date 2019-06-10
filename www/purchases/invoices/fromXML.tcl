ad_page_contract {
    Import invoice from XML format
} {
    file:optional
    file.tmpfile:optional
}

ad_form -name upload -html {enctype multipart/form-data} -form {
    {file:file
	{label "Upload"}
    }
} -on_submit {
    if {[info exists file] &&
	[info exists file.tmpfile] &&
	[file exists ${file.tmpfile}]} {
	::xo::dc transaction {
	    ::alt::PurchaseInvoice fromXML ${file.tmpfile}
	}
	ad_returnredirect list
	ad_script_abort
    }
}
