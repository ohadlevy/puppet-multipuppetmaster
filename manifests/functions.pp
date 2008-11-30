#Manages a site environment.
define modules($site = "", $type = "", $module = "", $version = "") {
	case $type {
		default: { $modulepath = "/etc/puppet/env/$site" }
		"testing": { $modulepath = "/etc/puppet/env/${site}_test" }
	}	
	case $type {
		default:   { $src_module_path = "$stable_module_path/$type" }
		"testing": { $src_module_path = "$testing_module_path" }
		"site":    { $src_module_path = "$sites_module_path" }
		"":        { $src_module_path = "$stable_module_path" }
	}
	case $version {
		"": { $seperator = "" }
		default: { $seperator = "_" }
	}
	file{"$modulepath/$module": ensure => link, target => "$src_module_path/$module$seperator$version",
		require => [File[$modulepath],Subversion::Svnserve["stable"],
			Subversion::Svnserve["sites"],Subversion::Svnserve["testing"]] 
 	}
}
define module_dir($type = "stable") {
	file { $name: 
		ensure => directory,
		recurse => true,
		purge => true,
		force => true,
		before => Subversion::Svnserve[$type] 
	} 
}

