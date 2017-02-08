<master>
  <property name="title">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

<h2>#altered.PurchaseInvoice#: <a href="edit?item_id=@invoice_id@">@invoice_num@</a></h2>
<h2>#altered.Date#: @invoice_date@</h2>
<h2>#altered.Party#: <a href="/@package_key@/parties/edit?item_id=@party_id@">@party_name@</a></h2>
<hr/>
<a class="button" href="@conf_reset_url@">
  <if @confirmed_p@ false>#altered.Confirm#</if>
  <else>#altered.Reset#</else>
</a>
<hr>
<include src="../../../lib/sale-invoice-lines" 
   item_id="@invoice_id@" 
/>
<hr>
<if @show_form_p@ true>
  <formtemplate id="@form_name@"></formtemplate>
</if>
