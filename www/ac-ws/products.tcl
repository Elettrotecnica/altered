ad_page_contract {
    Products autocompletion webservice
} {
    id:naturalnum,optional
    {query ""}
}

if {![info exists id]} {set id ""}

db_multirow data query "
  select code || ' - ' || name as name, product_id as id
    from alt_products
   where (:id is null or product_id = :id)
     and (:query is null or upper(code) || ' ' || upper(name) like '%' || upper(:query) || '%')
   order by code asc, name asc limit 30"

# "test [template::multirow columns data]"

alt::ac::return_xml data
