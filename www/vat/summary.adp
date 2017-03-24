<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

  <table style="vertical-align:top;">
    <tr>
      <td class="list-filter-pane" style="width:200px;">
        <formtemplate id="filter" style="filter"></formtemplate>
	<listfilters name="purchsummary"></listfilters>
      </td>
      <td class="list-list-pane">
      	<h2>#altered.Purchase#</h2>
	<listtemplate name="purchsummary"></listtemplate>
      </td>
    </tr>
    <tr>
      <td>
      </td>
      <td class="list-list-pane">
      	<h2>#altered.Sale#</h2>
	<listtemplate name="salesummary"></listtemplate>
      </td>
    </tr>
  </table>
