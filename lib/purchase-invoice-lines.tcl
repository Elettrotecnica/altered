
# expected parameters
# - class: class of the object
# - object_id: id of the parent object, containing the lines
# - line_id (optional): id of the line

set package_url [ad_conn package_url]

# prepare actions buttons
set bulk_actions [subst {
    "#acs-subsite.Delete#"  $package_url/call?m=delete "[_ altered.Delete_Line]"
}]

set elements {
    edit {
	link_url_col edit_url
	display_template {<img src="/resources/acs-subsite/Edit16.gif" width="16" height="16" border="0">}
	link_html {title "#altered.Edit_Line#"
	    id    @lines.line_id@}
	sub_class narrow
    }
    line_num {
	label "#altered.Line_Num#"
    }
    product_code {
	label "#altered.Product_Code#"
	link_url_col prod_view_url
	link_html {title "#altered.View/Edit#"}
    }
    product_description {
	label "#altered.Description#"
    }
    um_code {
	label "UM"
    }
    qty {
	label "#altered.Quantity#"
	html {align right}
    }
    price {
	label "#altered.Price#"
	html {align right}
    }
    line_price {
	display_col line_price_pretty
	label "#altered.Amount#"
	html {align right}
	aggregate "sum"
    }
    delete {
	link_url_col delete_url 
	display_template {<img src="/resources/acs-subsite/Delete16.gif" width="16" height="16" border="0">}
	link_html {title "#altered.Delete_Line#" class confirm}
	sub_class narrow
    }
}

template::list::create \
    -name lines \
    -multirow lines \
    -bulk_actions $bulk_actions \
    -bulk_action_export_vars {item_id} \
    -key line_id \
    -elements $elements

set this_url [export_vars -base [ad_conn url] -entire_form -no_empty]

db_multirow -extend {
    edit_url
    view_url
    prod_view_url
    line_price
    line_price_pretty
    delete_url
} lines query "
	select line_num, 
               l.invoice_id,
               l.invoice_line_id as item_id,
               l.invoice_line_id as line_id,
               l.product_id, 

               (select code from alt_unities_of_measurement
		  where unity_id = p.unity_id) as um_code,
               p.code as product_code,

               coalesce(l.description, p.name)            as product_description,
               l.qty,
               l.price
         from  alt_purchase_invoice_lines l,
               alt_products p

        where l.invoice_id = :item_id  
          and l.product_id   = p.product_id

     order by  line_num
    " {
	set edit_url      [export_vars -base [ad_conn url] {invoice_id item_id}]
        set delete_url    [export_vars -base ${package_url}call {item_id {m delete} {return_url $this_url}}]
        set prod_view_url [export_vars -base ${package_url}products/edit {{item_id $product_id}}]

	set line_price [expr {$price * $qty}]

	set qty               [lc_numeric $qty]
	set price             [lc_numeric $price]
	set line_price_pretty [lc_numeric $line_price]
    }

template::add_confirm_handler \
    -message [_ altered.Are_you_sure_you_want_to_delete?] \
    -CSSclass confirm
