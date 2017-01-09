ad_library {

    Autocomplete procs

    @author Antonio Pisano

}

namespace eval alt {}
namespace eval alt::ac {}

ad_proc -public alt::ac::return_xml {
    multirow
} { 
    <p>Ritorna alla connessione un xml adatto ad essere utilizzato dai campi autocompletati di Alter</p>
    <p>
      la multirow in ingresso puo' essere costruita a piacere, a patto che contenga tutte 
      e sole le colonne 'id' e 'name', che saranno poi rispettivamente id e nome nella tendina generata nelle pagine
    </p>
} { 
    set columns [template::multirow columns $multirow]
    set total   [template::multirow size $multirow]
    
    if {[lsort $columns] ne [lsort {"id" "name"}]} {
	error "The only columns allowed for this multirow are 'id' and 'name'"
    }

    # First create our top-level document
    dom createDocument xml doc
    set root [$doc documentElement]

    # Set xml version number and encoding
    $root setAttribute version "1.0"
    $root setAttribute encoding "UTF-8"

    # Create the commands to build up our XML document
    dom createNodeCmd elementNode success
    dom createNodeCmd elementNode total
    dom createNodeCmd textNode t

    foreach column $columns {
	dom createNodeCmd elementNode $column
    }

    $root appendFromScript {
	success {t "true"}
	total {t $total}
    }

    template::multirow foreach $multirow {
	set data [$doc createElement data]
	$root appendChild $data
	
	foreach column $columns {
	    $data appendFromScript {
		$column {t [set $column]}
	    }
	}
    }

    ns_return 200 text/xml [$root asXML]
}
