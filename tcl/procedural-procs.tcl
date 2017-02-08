ad_library {

    Procedural API

    @author Antonio Pisano

}

namespace eval alt {}
namespace eval alt::um {}

ad_proc -public alt::um::selbox {
} {
    
    Returns a list in ad_form select widget format for the unity of
    measure defined on the system
    
} {
    set selbox {}
    foreach um [[::alt::Unity get_instances_from_db \
		     -select_attributes {code,name,unity_id}] children] {
	set code [$um set code]
	set name [_ [string range [$um set name] 1 end-1]]
	lappend selbox [list "$code - $name" [$um set unity_id]]
    }
    return $selbox
}
