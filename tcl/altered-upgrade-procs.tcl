ad_library {
    Upgrade logics.
}

namespace eval alt::apm {}

ad_proc alt::apm::upgrade_callback {
    -from_version_name:required
    -to_version_name:required
} {
    ns_log notice "\n... entering apm_upgrade_logic ..."
    apm_upgrade_logic \
	-from_version_name $from_version_name \
	-to_version_name $to_version_name \
	-spec {
	    0.1d 0.2d {
		::xo::dc transaction {
		    foreach package_id [apm_package_ids_from_key \
					    -package_key "altered" -mounted] {
			array set node [site_node::get_from_object_id \
					    -object_id $package_id]
			set node_id $node(node_id)
			alt::apm::after_mount \
			    -package_id $package_id \
			    -node_id    $node_id
		    }
		}
	    }
	}
}
