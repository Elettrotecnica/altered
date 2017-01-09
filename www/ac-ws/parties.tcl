ad_page_contract {
    Parties autocompletion webservice
} {
    id:naturalnum,optional
    {query ""}
}

if {![info exists id]} {set id ""}

db_multirow data query "
  select code || ' - ' || title as name, party_id as id
    from alt_parties
   where (:id is null or party_id = :id)
     and (:query is null or upper(code) || ' ' || upper(title) like '%' || upper(:query) || '%')
   order by code asc, title asc limit 30"

# "test [template::multirow columns data]"

alt::ac::return_xml data
