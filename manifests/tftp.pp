class host-puppetmaster::tftp {
  include redhat::xinetd

  $tftp_dir="/var/kickstart/tftpboot"

  package {["tftp-server","syslinux"]:ensure => installed}

  pushmfiles {"/etc/xinetd.d/tftp":
    src  => "etc/xinetd.d/tftp",
    mode => 644,
    require => [Package["tftp-server"], Package["xinetd"]],
    notify  => Service["xinetd"]
  }

  file{["/var/kickstart",$tftp_dir,"$tftp_dir/gi-install", "$tftp_dir/gi-install/boot"]:
    ensure => directory
  }
  
  # Gini needs to write to this directory
  file {"$tftp_dir/gi-install/pxelinux.cfg": 
    ensure => directory, 
    group => apache, mode => 775, 
    require => User["apache"]
  }
  file {"$tftp_dir/gi-install/pxelinux.0":
    source => "/usr/lib/syslinux/pxelinux.0",
    mode => 644, owner => root,
    require => [Package["syslinux"],File["$tftp_dir/gi-install"]],
  }

# now setup all OS's required TFTP files
  tftp_OS {"GI2-i": dest => "$tftp_dir/gi-install", version => "2.0", arch => "i386"}
  tftp_OS {"GI2-x": dest => "$tftp_dir/gi-install", version => "2.0", arch => "x86_64"}
  tftp_OS {"GI4-i": dest => "$tftp_dir/gi-install", version => "4.0", arch => "i386"}
  tftp_OS {"GI4-x": dest => "$tftp_dir/gi-install", version => "4.0", arch => "x86_64"}
  tftp_OS {"GI5-i": dest => "$tftp_dir/gi-install", version => "5", arch => "i386"}
  tftp_OS {"GI5-x": dest => "$tftp_dir/gi-install", version => "5", arch => "x86_64"}
  #tftp_OS {"GI8": type => "Solaris", dest => "$tftp_dir", version => "5.8", arch => "sparc"}
  tftp_OS {"GI10": type => "Solaris", dest => "$tftp_dir", version => "5.10", arch => "sparc"}
  #tftp_OS {"GI10-x86": type => "Solaris", dest => "$tftp_dir", version => "5.10", arch => "x86}
}
