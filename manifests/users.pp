class host-puppetmaster::users inherits host-base::users {
  realize( User["root"] ) #make sure that user root is managed. 
  User ["root"] {password => 'hashhash'}

# local accounts and users
  group {"puppet": 
    ensure => present,
    require => [Package["puppet-server"], Exec["de-authconfig"]],
  } 
  user {"puppet":
    ensure => present,
    require => [Package["puppet-server"], Exec["de-authconfig"]],
  }

  # I guess this two resources should be ldap::disable and autofs::disable... maybe next version
  service{"autofs": ensure => stopped, enable => false}
  exec{"de-authconfig":
    command => "/usr/sbin/authconfig --usemd5 --disablenis --disableldap --disableldapauth \
             --disablesmartcard --disablerequiresmartcard --disablekrb5 --disablekrb5kdcdns \
             --disablesmbauth --disablewinbind --updateall --disablewinbindauth --disablewins \
             --disablesysnetauth --disablemkhomedir --kickstart && rm -rf /var/state/authconfiged",
    onlyif => "/usr/bin/test -f /var/state/authconfiged",
    before => Service["autofs"],
  }

  exec{"stop autofs":
    refreshonly => true,
    command => "/etc/init.d/autofs stop; /usr/bin/killall autofs; /usr/bin/killall -9",
    subscribe => Exec["de-authconfig"],
  }

  # create local padm account which is used for site administration
  if $hostname != $puppeteer {
    $padmhome = "/var/lib/padm"
    user {"padm":
      ensure   => present,
      gid      => puppet,
      home     => $padmhome,
      shell    => "/bin/bash",
      managehome => true,
      password => '',
      comment => "Puppetmaster service admin account",
      require  => [Group["puppet"], Exec["de-authconfig"]],
    }
    file {
      $padmhome: 
        ensure => directory,
        before => User["padm"],
        group => "puppet";
      "$padmhome/.ssh": 
        ensure => directory,
        require => User["padm"],
        owner => "padm", group => "puppet", mode => 500;
      "$padmhome/.ssh/authorized_keys":
        ensure => present,
        content => template("host-puppetmaster/padm_pubkey.erb"),
        require => [User["padm"], File["/var/lib/padm/.ssh"]],
        owner => "padm", group => "puppet", mode => 500;
    } 
    append_if_no_such_line{
      "poweroff and reboot sudo":
        file    => "/etc/sudoers",
        line    => "padm $hostname=NOPASSWD: /sbin/shutdown -h now\npadm $hostname=NOPASSWD: /sbin/reboot";
      "run puppet manually":
        file    => "/etc/sudoers",
        line    => "padm $hostname=NOPASSWD: /usr/bin/chk_puppet";
    }
  }
}
