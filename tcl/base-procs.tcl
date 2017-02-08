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
    ## Unities of measurement
    #
    
    ::xo::db::Class create Unity \
	-table_name "alt_unities_of_measurement" \
	-pretty_name   "#altered.Unity_of_Measurement#" \
	-pretty_plural "#altered.Unities_of_Measurement#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create code -unique true -not_null true
	    ::xo::db::Attribute create name -not_null true
	}

    # Defaults
    if {![::xo::dc 0or1row no_unities "
      select 1 from [::alt::Unity table_name] limit 1"]} {
	foreach {code name} {
	    Mt  #altered.Linear_Meter#
	    Lt  #altered.Liter#
	    Kg  #altered.Kilogram#
	    Num #altered.Number#
	} {
	    set c [Unity new -volatile -name $name -code $code]
	    $c save_new
	}
    }

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
	    ::xo::db::Attribute create price -datatype number
	    ::xo::db::Attribute create unity_id -datatype integer \
		-references "[::alt::Unity table_name]([alt::Unity id_column])" -index true
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
    ## Payment dates
    #

    ::xo::db::Class create PaymentDate \
	-id_column "date_id" \
    	-table_name "alt_pay_dates" \
	-pretty_name   "#altered.PayDate#" \
	-pretty_plural "#altered.PayDates#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create document_id -datatype integer \
		-references "acs_objects(object_id)" -index true
	    ::xo::db::Attribute create due_date -datatype date
	    ::xo::db::Attribute create closing_date -datatype date
	    ::xo::db::Attribute create amount -datatype number -not_null true -default 0
	}

    PaymentDate instproc delete {} {
	foreach payment [[alt::Payment get_instances_from_db \
			      -select_attributes {object_id} \
			      -where_clause "and date_id = ${:object_id}"] children] {
	    $payment delete
	}
	next
    }

    PaymentDate instproc paid_p {} {
	return [expr {${:closing_date} ne ""}]
    }
	
    PaymentDate instproc pay {} {
	if {[:paid_p]} return
	if {![info exists :paid_amount]  ||
	    ${:paid_amount} > ${:amount} ||
	    ${:paid_amount} < 0
	} {
	    set ${:paid_amount} ${:amount}
	}
	if {${:amount} == ${:paid_amount}} {
	    if {![info exists :closing_date] ||
		${:closing_date} < ${:due_date}
	    } {
		set today [clock format [clock seconds] -format "%Y-%m-%d"]
		set :closing_date $today
	    }
	}
	set p [Payment new -volatile \
		   -date_id ${:date_id} \
		   -date ${:closing_date} \
		   -amount ${:paid_amount}]	
	$p save_new
	:save
    }

    ::xo::db::Class create Payment \
	-id_column "payment_id" \
    	-table_name "alt_payments" \
	-pretty_name   "#altered.Payment#" \
	-pretty_plural "#altered.Payments#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create date_id -datatype integer \
		-references [alt::PaymentDate table_name]([alt::PaymentDate id_column]) -not_null true
	    ::xo::db::Attribute create date -datatype date
	    ::xo::db::Attribute create amount -datatype number -not_null true -default 0
	}

    ::xo::db::require index -table [::alt::Payment table_name] -col date_id

    #
    ## Document Counter
    #

    ::xo::db::Class create Counter \
	-id_column "counter_id" \
    	-table_name "alt_counters" \
	-pretty_name   "#altered.Counter#" \
	-pretty_plural "#altered.Counters#" \
	-superclass ::xo::db::Object -slots {
	    ::xo::db::Attribute create code -datatype text -not_null true -unique true
	    ::xo::db::Attribute create name -datatype text -not_null true
	}

    ::xo::db::require table alt_counter_numbers [subst {
	counter_id  {integer not null references [::alt::Counter table_name]([alt::Counter id_column])}
	document_id {integer not null references acs_objects(object_id) on delete cascade}
	number      {integer not null}
	date        {date not null}
    }]

    Counter instproc next {{-date ""}} {
	if {$date eq ""} {set date [clock format [clock seconds] -format "%Y-%m-%d"]}
	set year [lindex [split $date -] 0]
	set year_start "$year-01-01"
	set year_end "$year-12-31"

	# Base case: do we have number 1?
	if {![::xo::dc 0or1row query "
              select 1 from alt_counter_numbers
               where date between :year_start and :year_end
                 and counter_id = ${:counter_id}
                 and number = 1 limit 1"] &&
	    ![::xo::dc 0or1row query "
              select 1 from alt_counter_numbers
               where date between :year_start and :year_end
                 and counter_id = ${:counter_id}
                 and date < :date
                 and number > 1 limit 1"]} {
	    # one was not there
	    set next 0
	} else {
	    # Smallest number filling an hole and/or fitting the date.
	    # This must be comprised between the biggest for past
	    # documents and our date.
	    set next [::xo::dc get_value query "
             select min(c1.number)
               from alt_counter_numbers c1
                    left outer join alt_counter_numbers c2
                      on c1.counter_id = c2.counter_id and
                         c1.number     = c2.number - 1 and
                         c2.date between :year_start and :year_end
          where c1.date between :year_start and :year_end
            and c1.counter_id = ${:counter_id}
            and c1.date >= (
              select coalesce(max(date), date(:year_start))
                from alt_counter_numbers
                where counter_id = ${:counter_id}
                  and date < :date
                  and date between :year_start and :year_end)
            and c1.date <= :date
            and c2.number is null" ""]
	}

	if {$next eq ""} return

	return [incr next]
    }

    Counter instproc assign_number {-document_id -number -date} {
	::xo::dc dml save_number "
	    insert into alt_counter_numbers (
		     counter_id,
                     document_id,
                     number,
                     date
                  ) values (
		     ${:counter_id},
                     :document_id,
                     :number,
                     :date
                  )"
    }


    # Default counters for invoices
    if {![::xo::dc 0or1row no_counters "
      select 1 from [::alt::Counter table_name] limit 1"]} {
	foreach {code name} {
	    001 #altered.Purc_Invoices#
	    002 #altered.Sale_Invoices#
	} {
	    set c [Counter new -volatile -name $name -code $code]
	    $c save_new
	}
    }


    #
    ## Table Views
    #

    ::xo::dc dml drop_view "drop view if exists alt_document_amountsi cascade"
    ::xo::db::require view alt_document_amountsi "
      select document_id,
             sum(amount) as amount,
             coalesce(sum((select sum(amount) from [::alt::Payment table_name]
                   where date_id = d.[::alt::PaymentDate id_column])), 0)  as paid_amount
        from [::alt::PaymentDate table_name] d
         group by document_id"

}

::xo::library source_dependent
