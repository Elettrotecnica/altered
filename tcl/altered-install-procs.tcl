ad_library {
    Install callbacks.
}

namespace eval alt::apm {}

ad_proc -public alt::apm::after_mount {
    -package_id
    -node_id
} {
    After mount callback
} {
    # Instantiate a file-storage instance for the package
    set fs_package_id [site_node::instantiate_and_mount \
			-parent_node_id $node_id \
			-package_key "file-storage"]

    # Instantiate an attachments instance for the package
    site_node::instantiate_and_mount \
	-parent_node_id $node_id \
	-package_key "attachments" \
	-node_name "attach"

    # Map file-storage root folder to attachments for this package
    set root_folder_id [fs::get_root_folder -package_id $fs_package_id]
    attachments::map_root_folder \
	-package_id $package_id \
	-folder_id  $root_folder_id
}
