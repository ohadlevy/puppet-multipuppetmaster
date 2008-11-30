class host-puppetmaster::monit {
  # email address to send monit emails
  $monit_admin="email@domain.com"
  include monit::munin

  file { "/etc/monit.d/puppetmaster.conf":
    content => template("host-puppetmaster/monit.erb"),
    before  => Service["monit"],
    notify  => Service["monit"],
  }
  file { "/etc/monit.d/http-proxy.conf":
    content => template("host-puppetmaster/http-proxy.erb"),
    before  => Service["monit"],
    notify  => Service["monit"],
  }
  file {"/usr/bin/pm_control": mode => 540, owner => root, group => puppet,
    source  => "puppet://$servername/host-puppetmaster/push/usr/bin/pm_control",
    before  => Service["monit"],
  }
}
