class host-puppetmaster::apache inherits apache2::ssl {
	User["apache"] { groups => "puppet" }
	file {"/etc/httpd/conf.d/puppetmaster-vhost.conf":
		content => template("host-puppetmaster/puppetmaster-vhost.conf.erb"),
		require => Package["httpd"],
		notify  => Service["httpd"]
	}

	file {"/etc/httpd/conf.d/ssl.conf":
		content => template("host-puppetmaster/ssl.conf.erb"),
		require => Package["httpd"],
		notify  => Service["httpd"]
	}

	package {"rubygem-mongrel": ensure => present,
		require => [Package["gcc"], Yumrepo["addons"]],
		before  => [Service["puppetmaster"], Service["httpd"]]
	}

	file {"/etc/httpd/conf.d/mongrel-vhost.conf": 
		content => template("host-puppetmaster/mongrel-vhost.conf.erb"), 
		mode    => 644,
		require => [Package["httpd"], Package["rubygem-mongrel"]],
		before  => Service["httpd"]
	}
	package {"webalizer": ensure => installed}
	pushmfiles {"/etc/httpd/conf.d/webalizer.conf":
		src => "etc/httpd/conf.d/webalizer.conf",
		require => Package["httpd"],
		mode => 644
	}
}

class host-puppetmaster::apache-puppeteer inherits host-puppetmaster::apache {
	File ["/etc/httpd/conf.d/puppetmaster-vhost.conf"] {
		content => template("host-puppetmaster/puppetmaster-vhost.conf.erb.puppeteer")
	}
	File ["/etc/httpd/conf.d/ssl.conf"] {
		content => template("host-puppetmaster/ssl.conf.erb.puppeteer")
	}
}
