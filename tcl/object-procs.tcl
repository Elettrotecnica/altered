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
	    ::xo::db::Attribute create country
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

    Party instproc get_main_location {} {
	return [::xo::dc get_value get "
         select location_id from alt_party_locations
          where party_id = ${:party_id}
            and main_p" -default ""]
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
    ## Document
    #

    ::xo::db::Class create Document \
	-table_name "alt_documents" \
	-pretty_name   "#altered.Document#" \
	-pretty_plural "#altered.Documents#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create code -not_null true
	    ::xo::db::Attribute create year -datatype integer -not_null true
	    ::xo::db::Attribute create date -datatype date
	    ::xo::db::Attribute create party_id -datatype integer -references "[::alt::Party table_name]([alt::Party id_column])"
	    ::xo::db::Attribute create location_id -datatype integer -references "[::alt::Location table_name]([alt::Location id_column])"
	    ::xo::db::Attribute create description
	}

    ::xo::db::require index -table [::alt::Document table_name] -unique true -col "code,year"

    foreach col {party_id location_id} {
	::xo::db::require index -table [::alt::Document table_name] -col $col
    }

    #
    ## Document detail
    #

    ::xo::db::Class create DocumentDetail \
	-id_column "document_detail_id" \
	-table_name "alt_document_details" \
	-pretty_name   "#altered.Document_detail#" \
	-pretty_plural "#altered.Documents_details#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create document_id \
		-datatype integer -references "[::alt::Document table_name]([alt::Document id_column])" -not_null true
	    ::xo::db::Attribute create product_id \
		-datatype integer -references "[::alt::Product table_name]([alt::Product id_column])"
	    ::xo::db::Attribute create description
	    ::xo::db::Attribute create qty -datatype number
	    ::xo::db::Attribute create price -datatype number
	}

    foreach col {document_id product_id} {
	::xo::db::require index -table [::alt::DocumentDetail table_name] -col $col
    }

    #
    ## Purchase invoice
    #

    ::xo::db::Class create PurchaseInvoice \
	-id_column "invoice_id"	\
	-table_name "alt_purchase_invoices" \
	-pretty_name   "#altered.PurchaseInvoice#" \
	-pretty_plural "#altered.PurchaseInvoices#" \
	-superclass ::alt::Document

    ::xo::db::require view alt_purchase_invoicesi "
          select d.*, i.*
          from [::alt::Document        table_name] d,
               [::alt::PurchaseInvoice table_name] i
            where d.[alt::Document id_column] = i.[alt::PurchaseInvoice id_column]" \
	-rebuild_p true

    #
    ## Purchase invoice line
    #

    ::xo::db::Class create PurchaseInvoiceLine \
	-id_column "invoice_line_id" \
    	-table_name "alt_purchase_invoice_lines" \
	-pretty_name   "#altered.PurchaseInvoiceLine#" \
	-pretty_plural "#altered.PurchaseInvoiceLines#" \
	-superclass ::alt::DocumentDetail

    ::xo::db::require view alt_purchase_invoice_linesi "
          select dl.*, l.*
          from [::alt::DocumentDetail      table_name] dl,
               [::alt::PurchaseInvoiceLine table_name] l
            where dl.[alt::DocumentDetail id_column] = l.[alt::PurchaseInvoiceLine id_column]" \
	-rebuild_p true

    #
    ## Sale invoice
    #

    ::xo::db::Class create SaleInvoice \
	-id_column "invoice_id"	\
	-table_name "alt_sale_invoices" \
	-pretty_name   "#altered.SaleInvoice#" \
	-pretty_plural "#altered.SaleInvoices#" \
	-superclass ::alt::Document

    ::xo::db::require view alt_sale_invoicesi "
          select d.*, i.*
          from [::alt::Document    table_name] d,
               [::alt::SaleInvoice table_name] i
            where d.[alt::Document id_column] = i.[alt::SaleInvoice id_column]" \
	-rebuild_p true

    #
    ## Sale invoice line
    #

    ::xo::db::Class create SaleInvoiceLine \
	-id_column "invoice_line_id" \
    	-table_name "alt_sale_invoice_lines" \
	-pretty_name   "#altered.SaleInvoiceLine#" \
	-pretty_plural "#altered.SaleInvoiceLines#" \
	-superclass ::alt::DocumentDetail

    ::xo::db::require view alt_sale_invoice_linesi "
          select dl.*, l.*
          from [::alt::DocumentDetail  table_name] dl,
               [::alt::SaleInvoiceLine table_name] l
            where dl.[alt::DocumentDetail id_column] = l.[alt::SaleInvoiceLine id_column]" \
	-rebuild_p true


}
