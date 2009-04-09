class host-puppetmaster::monit {
  # email address to send monit emails
  $monit_admin="email@domain.com"
  include monit::munin

	file { "/etc/monit.d/puppetmaster.conf":
		content => template("host-puppetmaster/monit.erb"),
		notify  => Service["monit"],
	}
	file { "/etc/monit.d/http-proxy.conf":
		content => template("host-puppetmaster/http-proxy.erb"),
		notify  => Service["monit"],
	}
	file {"/usr/bin/pm_control": mode => 540, owner => root, group => puppet,
		source  => "puppet://$servername/host-puppetmaster/push/usr/bin/pm_control",
		before  => Service["monit"],
	}
  file {"/etc/monit.d/memcached.conf":
		source  => "puppet:///host-puppetmaster/push/etc/monit.d/memcached.conf",
		before  => Service["monit"],
	}
}
