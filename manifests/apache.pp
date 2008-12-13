# This class manages apache configuration for the puppetmaster service
# this includes, apache virtual host 
# mongrel process

class host-puppetmaster::apache inherits apache2::ssl {
	User["apache"] { groups => "puppet" }
	file {"/etc/httpd/conf.d/puppetmaster-vhost.conf":
		content => template("host-puppetmaster/puppetmaster-vhost.conf.erb"),
		require => Package["httpd"],
		notify  => Service["httpd"],
	}

	file {"/etc/httpd/conf.d/ssl.conf":
		content => template("host-puppetmaster/ssl.conf.erb"),
		require => Package["httpd"],
		notify  => Service["httpd"],
	}

	package {"rubygem-mongrel": ensure => present,
		require => [Package["gcc"], Yumrepo["addons"]],
		before  => [Service["puppetmaster"], Service["httpd"]]
	}

	file {"/etc/httpd/conf.d/mongrel-vhost.conf": 
		content => template("host-puppetmaster/mongrel-vhost.conf.erb"),
		mode    => 644,
		require => [Package["httpd"], Package["rubygem-mongrel"]],
		notify  => Service["httpd"],
	}
	package {"webalizer": ensure => installed}
	pushmfiles {"/etc/httpd/conf.d/webalizer.conf":
		src => "etc/httpd/conf.d/webalizer.conf",
		require => Package["httpd"],
		notify  => Service["httpd"],
		mode => 644
	}
}

# this class handles special options which are used differently on the
# puppeteer 
class host-puppetmaster::apache-puppeteer inherits host-puppetmaster::apache {
	File ["/etc/httpd/conf.d/puppetmaster-vhost.conf"] {
		content => template("host-puppetmaster/puppetmaster-vhost.conf.erb.puppeteer")
	}
  # no need for SSL on the puppeteer as GINI doesn't run on it
	File ["/etc/httpd/conf.d/ssl.conf"] {
		ensure => absent,
    notify => Service["httpd"],
	}
	# no autosign on the puppeteer
	file {"/etc/puppet/autosign.conf": ensure => absent} 
}
