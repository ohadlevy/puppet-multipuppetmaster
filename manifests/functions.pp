#Manages a site environment.
define modules($env ="", $site = "", $type = "", $module, $version = "") {

  # to support simple transition between the $site and $env 
  $real_env =  $env ? { "" => $site, default => $env }

  # note testing type refer only to testing modules, if a site wants to test a module, they should just use it
  # in a testing env!
  $modulepath = $type ? {
    default => "/etc/puppet/env/$real_env",
    "testing" => "/etc/puppet/env/${real_env}_test",
  }

  $src_module_path = $type ? {
    default => "$stable_module_path/$type",
    "testing" => $testing_module_path,
    "site"    => $sites_module_path,
    ""        => $stable_module_path,
  }

  $seperator = $version ? { "" => "", default => "_" }

  file{"$modulepath/$module": ensure => link,
    target => "$src_module_path/$module$seperator$version",
    require => File[$modulepath],
  }
}

define module_dir($type = "stable") {
  file { $name:
    ensure => directory, recurse => true,
    purge => true, force => true,
    before => File["/etc/puppet/puppet.conf"],
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
  $path_prefix = $type ? { "RedHat" => "/opt/goldenimage_", "Solaris" => "/opt/solgi_"}
  File{ mode => 444, links => follow, 
    require => [Service["autofs"],Host-puppetmaster::Nfs::Mnt["${path_prefix}${version}"]],
  }

  case $type {
    "RedHat": {
      file{"${dest}/boot/vmlinuz-gi${ver}.$arch":
        source => "${path_prefix}${version}/$arch${path}${install}/images/pxeboot/vmlinuz",
      }
      file{"${dest}/boot/initrd-gi${ver}.$arch":
        source => "${path_prefix}${version}/$arch${path}${install}/images/pxeboot/initrd.img",
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
      case $arch {
        default: {
          file{"${dest}/inetboot.${arch}.Solaris_${ver}":
            source => "${path_prefix}${version}/tftp/inetboot.${arch}.Solaris_${ver}",
          }
        }
        "i86pc": {
          file{"${dest}/inetboot.SUNW.Solaris_10.i86pc":
            source => "${path_prefix}${version}/tftp/SUNW.i86pc"
          }
        }
      }
    }
  }
}
