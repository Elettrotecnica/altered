::xo::library doc {

    System objects

    @author Antonio Pisano

}

namespace eval ::alt {

    #
    ## Altered Package
    #

    set p [::xo::PackageMgr create Package \
	       -superclass  ::xo::Package \
	       -package_key  altered \
	       -pretty_name "#altered.Altered_Package#"]

    #
    ## Location
    #

    # ::xo::db::Attribute create location -datatype "GEOGRAPHY(POINT,4326)"
    ::xo::db::Class create Location \
	-table_name "alt_locations" \
	-pretty_name   "#altered.Location#" \
	-pretty_plural "#altered.Locations#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create name -not_null true
	    ::xo::db::Attribute create street
	    ::xo::db::Attribute create number
	    ::xo::db::Attribute create city
	    ::xo::db::Attribute create zone
	    ::xo::db::Attribute create region
	    ::xo::db::Attribute create country -references "countries(iso)"
	}

    #
    ## Party
    #

    ::xo::db::Class create Party \
	-table_name "alt_parties" \
	-pretty_name   "#altered.Party#" \
	-pretty_plural "#altered.Parties#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create code -unique true -not_null true
	    ::xo::db::Attribute create title -not_null true
	    ::xo::db::Attribute create tax_code -unique true
	    ::xo::db::Attribute create vat_number -unique true
	}

    ::xo::db::require sequence \
	-name alt_parties_party_code_seq \
	-start_with 1 -increment_by 1

    Party instproc get_main_location {} {
	return [::xo::dc get_value get "
         select location_id from alt_party_locations
          where party_id = ${:party_id}
            and main_p" ""]
    }

    Party instproc gen_code {} {
	if {${:code} eq ""} {
	    set :code [format "%06s" [::xo::dc get_value nextval "
              select nextval('alt_parties_party_code_seq')"]]
	}
    }

    Party instproc delete {} {
	set locations [::xo::dc list get_locations "
          select location_id from alt_party_locations 
           where party_id = ${:party_id}"]
	::xo::dc dml delete_locations "
         delete from alt_party_locations 
          where party_id = ${:party_id}"
	foreach location_id $locations {
	    set l [::xo::db::Class get_instance_from_db \
		       -id $location_id]
	    $l delete
	}
	next
    }

    Party instproc save_new {} {
	:gen_code
	next
    }

    Party instproc save {} {
	:gen_code
	next
    }
    

    # Party locations

    ::xo::db::require table alt_party_locations [subst {
	party_id    {integer not null references [::alt::Party table_name]([alt::Party id_column])}
        location_id {integer not null references [::alt::Location table_name]([alt::Location id_column])}
	name        {text not null}
	description {text}
	main_p      {boolean default 'f'}
    }]

    foreach col {party_id location_id} {
	::xo::db::require index -table alt_party_locations -col $col
    }

    ::xo::db::require view alt_partiesi "
          select p.*, l.*,
                 pl.name as location_name,
                 pl.description as location_description
          from [::alt::Party    table_name] p
               left join alt_party_locations pl on pl.party_id = p.[alt::Party id_column]
               left join [::alt::Location table_name] l on pl.location_id = l.[alt::Location id_column]
            where (pl.party_id is null or pl.main_p)" \
	-rebuild_p true

    #
    ## Product
    #

    ::xo::db::Class create Product \
	-table_name "alt_products" \
	-pretty_name   "#altered.Product#" \
	-pretty_plural "#altered.Products#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create code -unique true -not_null true
	    ::xo::db::Attribute create name -not_null true
	    ::xo::db::Attribute create description
	}

    ::xo::db::require sequence \
	-name alt_products_product_code_seq \
	-start_with 1 -increment_by 1

    Product instproc gen_code {} {
	if {${:code} eq ""} {
	    set :code [format "%06s" [::xo::dc get_value nextval "
              select nextval('alt_products_product_code_seq')"]]
	}
    }

    Product instproc save_new {} {
	:gen_code
	next
    }

    Product instproc save {} {
	:gen_code
	next
    }

    #
    ## Purchase invoice
    #

    ::xo::db::Class create PurchaseInvoice \
	-id_column "invoice_id"	\
	-table_name "alt_purchase_invoices" \
	-pretty_name   "#altered.PurchaseInvoice#" \
	-pretty_plural "#altered.PurchaseInvoices#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create invoice_num -not_null true
	    ::xo::db::Attribute create invoice_year -datatype integer -not_null true	    
	    ::xo::db::Attribute create date -datatype date
	    ::xo::db::Attribute create party_id -datatype integer -references "[::alt::Party table_name]([alt::Party id_column])"
	    ::xo::db::Attribute create location_id -datatype integer -references "[::alt::Location table_name]([alt::Location id_column])"
	    ::xo::db::Attribute create description
	    ::xo::db::Attribute create confirmed_p -datatype boolean -default false	    
	}

    foreach col {party_id location_id} {
	::xo::db::require index -table [::alt::PurchaseInvoice table_name] -col $col
    }

    ::xo::db::require index -table [::alt::PurchaseInvoice table_name] -unique true -col "invoice_num,invoice_year"

    PurchaseInvoice instproc confirm {} {
	if {${:confirmed_p}} return
	set amount [::xo::dc get_value get_amount "
         select sum(price * qty) from [::alt::PurchaseInvoiceLine table_name]
          where invoice_id = ${:invoice_id}"]
	set d [PaymentDate new -volatile \
		   -document_id ${:invoice_id} \
		   -amount      $amount \
		   -due_date    ${:date}]
	$d save_new
	set :confirmed_p true
    }

    PurchaseInvoice instproc reset {} {
	if {!${:confirmed_p}} return
	foreach date_id [::xo::dc list get_dates "
           select date_id from [::altered::PayDates table_name]
            where document_id = ${:invoice_id}"] {	    
	    ::xo::db::Class delete -id $item_id
	}
	set :confirmed_p false
    }    

    #
    ## Purchase invoice line
    #

    ::xo::db::Class create PurchaseInvoiceLine \
	-id_column "invoice_line_id" \
    	-table_name "alt_purchase_invoice_lines" \
	-pretty_name   "#altered.PurchaseInvoiceLine#" \
	-pretty_plural "#altered.PurchaseInvoiceLines#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create invoice_id \
		-datatype integer -references "[::alt::PurchaseInvoice table_name]([alt::PurchaseInvoice id_column])" -not_null true
	    ::xo::db::Attribute create product_id \
		-datatype integer -references "[::alt::Product table_name]([alt::Product id_column])"
	    ::xo::db::Attribute create description
	    ::xo::db::Attribute create qty -datatype number
	    ::xo::db::Attribute create price -datatype number
	}

    foreach col {invoice_id product_id} {
	::xo::db::require index -table [::alt::PurchaseInvoiceLine table_name] -col $col
    }

    #
    ## Sale invoice
    #

    ::xo::db::Class create SaleInvoice \
	-id_column "invoice_id"	\
	-table_name "alt_sale_invoices" \
	-pretty_name   "#altered.SaleInvoice#" \
	-pretty_plural "#altered.SaleInvoices#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create invoice_num -not_null true
	    ::xo::db::Attribute create invoice_year -datatype integer -not_null true	    
	    ::xo::db::Attribute create date -datatype date
	    ::xo::db::Attribute create party_id -datatype integer -references "[::alt::Party table_name]([alt::Party id_column])"
	    ::xo::db::Attribute create location_id -datatype integer -references "[::alt::Location table_name]([alt::Location id_column])"
	    ::xo::db::Attribute create description
	    ::xo::db::Attribute create confirmed_p -datatype boolean -default false	    
	}

    foreach col {party_id location_id} {
	::xo::db::require index -table [::alt::SaleInvoice table_name] -col $col
    }

    ::xo::db::require index -table [::alt::SaleInvoice table_name] -unique true -col "invoice_num,invoice_year"

    SaleInvoice instproc confirm {} {
	if {${:confirmed_p}} return
	set amount [::xo::dc get_value get_amount "
         select sum(price * qty) from [::alt::SaleInvoiceLine table_name]
          where invoice_id = ${:invoice_id}"]
	set d [PaymentDate new -volatile \
		   -document_id ${:invoice_id} \
		   -amount      $amount \
		   -due_date    ${:date}]
	$d save_new
	set :confirmed_p true
    }

    SaleInvoice instproc reset {} {
	if {!${:confirmed_p}} return
	foreach date_id [::xo::dc list get_dates "
           select date_id from [::altered::PayDates table_name]
            where document_id = ${:invoice_id}"] {	    
	    ::xo::db::Class delete -id $item_id
	}
	set :confirmed_p false
    }
    

    #
    ## Sale invoice line
    #

    ::xo::db::Class create SaleInvoiceLine \
	-id_column "invoice_line_id" \
    	-table_name "alt_sale_invoice_lines" \
	-pretty_name   "#altered.SaleInvoiceLine#" \
	-pretty_plural "#altered.SaleInvoiceLines#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create invoice_id \
		-datatype integer -references "[::alt::SaleInvoice table_name]([alt::SaleInvoice id_column])" -not_null true
	    ::xo::db::Attribute create product_id \
		-datatype integer -references "[::alt::Product table_name]([alt::Product id_column])"
	    ::xo::db::Attribute create description
	    ::xo::db::Attribute create qty -datatype number
	    ::xo::db::Attribute create price -datatype number
	}

    foreach col {invoice_id product_id} {
	::xo::db::require index -table [::alt::SaleInvoiceLine table_name] -col $col
    }

    #
    ## Payment dates
    #

    ::xo::db::Class create PaymentDate \
	-id_column "date_id" \
    	-table_name "alt_pay_dates" \
	-pretty_name   "#altered.PayDate#" \
	-pretty_plural "#altered.Paydates#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create document_id -datatype integer -references "acs_objects(object_id)"
	    ::xo::db::Attribute create due_date -datatype date
	    ::xo::db::Attribute create closing_date -datatype date
	    ::xo::db::Attribute create amount -datatype number -not_null true -default 0
	}

    ::xo::db::require index -table [::alt::PaymentDate table_name] -col document_id

    ::xo::db::Class create Payment \
	-id_column "payment_id" \
    	-table_name "alt_payments" \
	-pretty_name   "#altered.Payment#" \
	-pretty_plural "#altered.Payments#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create date_id -datatype integer -references [alt::PaymentDate table_name]([alt::PaymentDate id_column])
	    ::xo::db::Attribute create date -datatype date
	    ::xo::db::Attribute create amount -datatype number -not_null true -default 0
	}

    ::xo::db::require index -table [::alt::Payment table_name] -col date_id

    #
    ## Table Views
    #

    ::xo::dc dml drop_view "drop view if exists alt_document_amountsi cascade"
    ::xo::db::require view alt_document_amountsi "
      select document_id,
             sum(amount) as amount,
             sum((select sum(amount) from [::alt::Payment table_name] 
                   where date_id = [::alt::PaymentDate id_column]))  as paid_amount
        from [::alt::PaymentDate table_name] d
         group by document_id"
    
    ::xo::db::require view alt_purchase_invoicesi "
          select i.*,
                 p.code as party_code,
                 p.title as party_name, 
                 coalesce(am.amount, 0) as amount,
                 coalesce(am.paid_amount, 0) as paid_amount
          from [::alt::PurchaseInvoice table_name] i
               left join alt_document_amountsi am on i.[alt::PurchaseInvoice id_column] = am.document_id,
               [::alt::Party table_name] p
            where i.party_id = p.[::alt::Party id_column]" \
	-rebuild_p true

    ::xo::db::require view alt_purchase_invoice_linesi "
          select l.*,
                 p.code as product_code,
                 p.name as product_name,
                 p.description as product_description
          from [::alt::PurchaseInvoiceLine table_name] l,
               [::alt::Product table_name] p
            where l.product_id = p.[alt::Product id_column]" \
	-rebuild_p true

    ::xo::db::require view alt_sale_invoicesi "
          select i.*,
                 p.code as party_code,
                 p.title as party_name, 
                 coalesce(am.amount, 0) as amount,
                 coalesce(am.paid_amount, 0) as paid_amount
          from [::alt::SaleInvoice table_name] i
               left join alt_document_amountsi am on i.[alt::SaleInvoice id_column] = am.document_id,
               [::alt::Party table_name] p
            where i.party_id = p.[::alt::Party id_column]" \
	-rebuild_p true

    ::xo::db::require view alt_sale_invoice_linesi "
          select l.*,
                 p.code as product_code,
                 p.name as product_name,
                 p.description as product_description
          from [::alt::SaleInvoiceLine table_name] l,
               [::alt::Product table_name] p
            where l.product_id = p.[alt::Product id_column]" \
	-rebuild_p true

}
