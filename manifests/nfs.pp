class host-puppetmaster::nfs {
    
  Mnt {require => Service["autofs"]}
  mnt {"/opt/goldenimage_5": device => "s02:/vol/s02/goldenimage_5"}
  mnt {"/opt/goldenimage_4.0": device => "s02:/vol/s02/goldenimage_4.0"}
  mnt {"/opt/goldenimage_2.0": device => "s02:/vol/s02/goldenimage_2.0"}
  mnt {"/opt/solgi_5.10": device => "s02:/vol/s02/solgi_5.10"}

  define mnt($device) {
    file {$name: 
      ensure => directory,
      owner => undef, group => undef
    }

    mount{$name:
      device => $device,
      ensure => mounted,
      fstype => nfs,
      atboot => true,
      options => "defaults",
      require => File[$name],
    }
  }
}


