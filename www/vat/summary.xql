<?xml version="1.0"?>

<queryset>

  <fullquery name="purc_multirow_query">
    <querytext>
      select v.name as vat_name,
             sum(deductible_tax_amount) as deductible_amount,
             sum(undeductible_tax_amount) as undeductible_amount
	from alt_purchase_invoice_lines l,
	     alt_purchase_invoices i,
	     alt_vats v
       where i.date between :from_date and :to_date
         and i.confirmed_p
         and i.invoice_id = l.invoice_id
	 and l.vat_id = v.vat_id
	 [template::list::filter_where_clauses -name purchsummary -and]
	  group by v.vat_id
         [template::list::orderby_clause -name purchsummary -orderby]
    </querytext>
  </fullquery>

  <fullquery name="sale_multirow_query">
    <querytext>
      select v.name as vat_name,
             sum(deductible_tax_amount) as deductible_amount,
             sum(undeductible_tax_amount) as undeductible_amount
	from alt_sale_invoice_lines l,
	     alt_sale_invoices i,
	     alt_vats v
       where i.date between :from_date and :to_date
         and i.invoice_id = l.invoice_id
         and i.confirmed_p
	 and l.vat_id = v.vat_id
	[template::list::filter_where_clauses -name salesummary -and]
	 group by v.vat_id
        [template::list::orderby_clause -name salesummary -orderby]
    </querytext>
  </fullquery>

</queryset>
