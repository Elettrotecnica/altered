ad_library {

    Procedural API

    @author Antonio Pisano

}

namespace eval alt {}
namespace eval alt::um {}

ad_proc -public alt::selbox {
    -class:required
} {

    Returns a list in ad_form select widget format for all instances
    defined for the kind of object specified

} {
    set id_column [$class id_column]
    set selbox {}
    foreach o [[$class get_instances_from_db \
		     -select_attributes [subst {code,name,$id_column}]] children] {
	set code [$o set code]
	set name [$o set name]
	if {[string match "#*#" $name]} {
	    set name [_ [string range $name 1 end-1]]
	}
	lappend selbox [list "$code - $name" [$o set $id_column]]
    }
    return [lsort -index 0 $selbox]
}

namespace eval alt {}
namespace eval alt::um {}

ad_proc -public alt::um::selbox {
} {

    Returns a list in ad_form select widget format for the unity of
    measure defined on the system

} {
    return [ns_memoize [::alt::selbox -class ::alt::Unity]]
}

namespace eval alt {}
namespace eval alt::vat {}

ad_proc -public alt::vat::selbox {
} {

    Returns a list in ad_form select widget format for the VATs
    defined on the system

} {
    return [::alt::selbox -class ::alt::VAT]
}
