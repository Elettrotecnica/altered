ad_page_contract {
    Attachments list
} {
    object_id:integer

    {search_name          ""}
    {search_file          ""}
    {f_mime_type          ""}
    {from_date            ""}
    {to_date              ""}

    {context ""}

    {rows_per_page 30}
    orderby:optional
    page:optional
}


# Check and retrieve object
if {[catch {
  acs_object::get \
    -object_id $object_id \
    -array object
}]} {
    ns_returnnotfound
    ad_script_abort
}

set object_type        $object(object_type)
set pretty_object_name $object(object_name)

acs_object_type::get \
  -object_type $object_type \
  -array obtype
set type_name   $obtype(pretty_name)
set type_plural $obtype(pretty_plural)


# creates filters form
ad_form \
    -name filter \
    -edit_buttons [list [list "Go" go]] \
    -export {object_id context} \
    -form {
	{search_name:text,optional
	    {label "#altered.Search_name#"}
	    {html {length 20} }
	    {value $search_name}
	}
	{search_file:text,optional
	    {label "#altered.Search_file_name#"}
	    {html {length 20} }
	    {value $search_file}
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
	{f_mime_type:text(select),optional
	    {label "#file-storage.Type#"}
            {options { {"Tutti" ""} [alt::file_extensions_selbox]}}
	    {value $f_mime_type}
	}
    } -on_request {

	set from_date_ansi ""
	set to_date_ansi   ""

    } -on_submit {

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

    }


set this_url [ad_return_url]

# User can specify context for this page directly by page contract
# parameters
set page_title "#altered.Attachments# ${type_name} - ${pretty_object_name}"
if {$context eq ""} {
    set breadcrumbs [list $page_title]
} else {
    set breadcrumbs $context
    lappend breadcrumbs $page_title
}

# get file-storage package id and folder
set fs_package_id [site_node::get_children \
		       -node_id [ad_conn node_id] \
		       -package_key "file-storage" \
		       -element "package_id"]
set folder_id [fs::get_root_folder -package_id $fs_package_id]

set attachments_url [site_node::get_children \
			 -node_id [ad_conn node_id] \
			 -package_key "attachments"]

# creates attachments url
set attachment_add_url [export_vars \
			    -base "${attachments_url}file-add" \
			    {pretty_object_name folder_id object_id {return_url $this_url}}]


# prepare actions buttons
set actions [list "#attachments.lt_Upload_New_Attachment#" $attachment_add_url "#attachments.lt_Upload_New_Attachment#"]


foreach attachment [attachments::get_attachments -object_id $object_id -base_url [ad_conn package_url]] {
    lassign $attachment attachment_id name view_url
    set files($attachment_id) [list $name $view_url]
}

if {[array size files] == 0} {
  set files_clause " 1 = 2 "
} else {
  set files_clause " file_id in ([join [array names files] ,]) "
}

if {![info exists errnum]} {
    set page_query "
	select file_id
	from fs_files f
	where ${files_clause} "
} else {
    set page_query "
	select file_id
	from fs_files f
	where 1 = 2 "
    template::multirow create attachments dummy
}

template::list::create \
    -name attachments \
    -multirow attachments \
    -actions $actions \
    -page_flush_p t \
    -page_size $rows_per_page \
    -page_groupsize  10 \
    -page_query {
	$page_query
	[template::list::filter_where_clauses -name attachments -and]
	[template::list::orderby_clause -name attachments -orderby]
      } \
    -elements {
	name {
	    label "#altered.Name#"
	    link_url_col view_url
	    link_html {title "#acs-kernel.common_View#"}
	}
	filename {
	    label "File"
	}
	size {
	    label "#file-storage.Size#"
	}
	username {
	    label "#acs-admin.Creation_user#"
	}
	last_modified {
	    label "#file-storage.Last_Modified#"
	}
	delete {
	    link_url_col delete_url
            link_html {title "#file-storage.Delete#" class "confirm-delete"}
	    display_template {<img src="/resources/acs-subsite/Delete16.gif" width="16" height="16" border="0">}
	    sub_class narrow
	}
    } \
    -filters {
	search_name {
	    hide_p 1
            where_clause {(:search_name is null or upper(file_upload_name) like '%' || upper(:search_name) || '%')}
	}
	search_file {
	    hide_p 1
            where_clause {(:search_file is null or upper(name) like '%' || upper(:search_file) || '%')}
	}
	f_mime_type {
	    hide_p 1
	    where_clause {(:f_mime_type is null or type = :f_mime_type)}
	}
        from_date {
            hide_p 1
            where_clause {(:from_date_ansi is null or last_modified >= :from_date_ansi)}
        }
        to_date {
            hide_p 1
            where_clause {(:to_date_ansi is null or last_modified <= :to_date_ansi)}
        }
	object_id {
	    hide_p 1
	}
	context {
	    hide_p 1
	}
        rows_per_page {
	    label "#altered.Rows_per_page#"
  	    values {{10 10} {30 30} {100 100} {"#acs-kernel.common_All#" 9999999}}
	    where_clause {1 = 1}
            default_value 30
        }
    } \
    -orderby {
	default_value name,asc
	name {
	    label "#altered.Name#"
	    orderby f.file_upload_name
	}
	filename {
	    label "File"
	    orderby f.name
	}
	size {
	    label "#file-storage.Size#"
	    orderby f.content_size
	}
	last_modified {
	    label "[_ file-storage.Last_Modified]"
	    orderby f.last_modified
	}
    }

db_multirow -extend {
  view_url
  username
  delete_url
} attachments query "
    select
      f.*,
      last_modified,
      name as filename,
      file_upload_name as name,
      content_size as size
      from fs_files f
    where 1 = 1
    [template::list::page_where_clause -name attachments -key file_id -and]
    [template::list::orderby_clause -name attachments -orderby]" {
	acs_object::get -object_id $file_id -array obj
	acs_user::get -user_id $obj(creation_user) -array user
	set username "$user(first_names) $user(last_name)"
	set view_url [lindex $files($file_id) 1]
	set delete_url [export_vars -base "${attachments_url}detach" {object_id {attachment_id $file_id} {return_url $this_url}}]
	set last_modified [lc_time_fmt $last_modified %x]
}
