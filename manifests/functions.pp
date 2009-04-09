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

define pxe_file($dest, $version, $arch, $port = "", $baud = "") {
  case $port {
    "": { $filename = "$dest/gi$version-$arch"}
    default: { $filename = "$dest/gi$version-$arch-$port-$baud"}
  }

  file {$filename:
    content => template("host-puppetmaster/pxe-gi.erb"),
    mode => 444, owner => root, group => root,
    require => File["$dest"],
  }
}
    
define tftp_OS($type = "RedHat", $dest, $version, $arch ) {
# work around for inconsistent directory structure
  case $version {
    "2.0":   {
      $ver = "2"
      $path = "_ws"
      $install = "/install"
    }
    "4.0":   {
      $ver = "4"
      $install = "/install"
      }
    "5.8":   {$ver = "8"}
    "5.10":  {$ver = "10"}
    default: {$ver = $version }
  }

  # set some defaults:
  File{ mode => 444, require => Service["autofs"], links => follow, }

  case $type {
    "RedHat": {
      file{"${dest}/boot/vmlinuz-gi${ver}.$arch":
        source => "/opt/goldenimage_${version}/$arch${path}${install}/images/pxeboot/vmlinuz",
      }
      file{"${dest}/boot/initrd-gi${ver}.$arch":
        source => "/opt/goldenimage_${version}/$arch${path}${install}/images/pxeboot/initrd.img",
      }
      # setup pxelinux boot files w and without serial access
      pxe_file{"pxe-GI${ver}-$arch": arch => $arch, dest => "${dest}/pxelinux.cfg", version => $ver}
      pxe_file{"pxe-GI${ver}-$arch-0-9600": 
        arch => $arch, port => "0", baud => "9600", 
        dest => "${dest}/pxelinux.cfg", version => $ver
      }
      pxe_file{"pxe-GI${ver}-$arch-0-115200": 
        arch => $arch, port => "0", baud => "115200", 
        dest => "${dest}/pxelinux.cfg", version => $ver
      }
      pxe_file{"pxe-GI${ver}-$arch-1-9600": 
        arch => $arch, port => "1", baud => "9600", 
        dest => "${dest}/pxelinux.cfg", version => $ver
      }
      pxe_file{"pxe-GI${ver}-$arch-1-115200": 
        arch => $arch, port => "1", baud => "115200", 
        dest => "${dest}/pxelinux.cfg", version => $ver
      }
    }
    "Solaris": {
      file{"${dest}/inetboot.SUN4U.Solaris_${ver}":
        source => "/opt/solgi_${version}/tftp/inetboot.SUN4U.Solaris_${ver}",
      }
    }
  }
}
