<?xml version="1.0"?>

<queryset>

  <fullquery name="paginator">
    <querytext>
      select invoice_id
      from alt_purchase_invoicesi
      where 1 = 1
      [template::list::filter_where_clauses -name invoices -and]
      [template::list::orderby_clause -name invoices -orderby]
    </querytext>
  </fullquery>

  <fullquery name="dummy_paginator">
    <querytext>
      select invoice_id
      from alt_purchase_invoicesi
      where 1 = 2
    </querytext>
  </fullquery>

  <fullquery name="multirow_query">
    <querytext>
      select invoice_id,
             invoice_num,
	     date,
	     party_id,
	     party_name,
	     round(amount, 2) as amount,
	     round(paid_amount, 2) as paid_amount,
	     confirmed_p
      from alt_purchase_invoicesi
      where 1 = 1
      [template::list::page_where_clause -name invoices -key invoice_id -and]
      [template::list::orderby_clause -name invoices -orderby]
    </querytext>
  </fullquery>

</queryset>
