class host-puppetmaster::puppetmaster {
	include mysql::server

	Package {require => Yumrepo["addons"]}

	package {"puppet-server": ensure => "0.24.4-1.el5", alias => puppetmaster }
	package { [ "rrdtool", "rubygem-RubyRRDtool" ]:
		ensure      => present,
		before      => Service["puppetmaster"]
	}
	file {"/usr/lib/ruby/site_ruby/1.8/i386-linux/RRDtool.so": ensure => link,
		target =>  "/usr/lib/ruby/gems/1.8/gems/RubyRRDtool-0.6.0/RRDtool.so",
		require => Package["rubygem-RubyRRDtool"] 
	}

	group {"puppet": ensure => present} 
	user {"padm":
		ensure   => present,
		gid      => puppet,
		home     => "/var/lib/puppet/files",
		shell    => "/bin/bash",
		password => 'hashahas'
		require  => Group["puppet"]
	}

	file {"/etc/puppet/puppet.conf": mode => 640, owner => puppet, group => puppet, 
				content => template("host-puppetmaster/puppet.conf"),
				before => Service["puppetmaster"] ,require => Package["puppetmaster"] 
	}
	case $hostmode {
		"development": {
			delete_lines { "No mail from development puppetmasters":
				file => "/etc/puppet/tagmail.conf",
				pattern => "store,rrdgraph,tagmail/store,rrdgraph"}
		}
		"production": {
			append_if_no_such_line {"tagmail":
				file => "/etc/puppet/tagmail.conf",
				line => "all: email@domain.com"	}
			append_if_no_such_line {"Point puppet at the puppeteer":
				file        => "/etc/sysconfig/puppet",
				line        => "PUPPET_SERVER=puppeteer.fqdn.com",
				require     => Package["puppetmaster"],
				before      => Service["puppetmaster"]}
		}
	}
	case $gi {
		5: {
			staticmfiles {"/etc/init.d/puppetmaster":    
				mode    => 755, 
				src     => "etc/init.d/puppetmaster",
				notify  => Service["puppetmaster"],
				require => Package["puppetmaster"], 
				before  => Service["puppetmaster"]
			}
			staticmfiles {"/etc/sysconfig/puppetmaster": 
				mode    => 644, 
				src     => "etc/sysconfig/puppetmaster",
				notify  => Service["puppetmaster"],
				require => Package["puppetmaster"], 
				before  => Service["puppetmaster"]
			}
		}
	}
	service {"puppetmaster": 
		require    => Package["puppetmaster"],
		before     => Service["httpd"],
		enable     => true,
		ensure     => running,
		hasrestart => true,
		hasstatus  => true
	}

# Manage puppet configuration files
	file {"/etc/puppet/node": mode => 550, owner => root, group => puppet,
		source => "puppet://$servername/host-puppetmaster/push/etc/puppet/node",
		before => Service["puppetmaster"] }
	file {"/etc/puppet/namespaceauth.conf": mode => 550, owner => root, group => puppet,
		source => "puppet://$servername/host-puppetmaster/push/etc/puppet/namespaceauth.conf", 
		before => Service["puppetmaster"] }
	file {"/etc/puppet/fileserver.conf": mode => 550, owner => root, group => puppet,
		source => "puppet://$servername/host-puppetmaster/push/etc/puppet/fileserver.conf", 
		before => Service["puppetmaster"] }
	file {"/etc/puppet/manifests": ensure => directory}
	file {"/etc/puppet/manifests/site.pp": mode => 550, owner => root, group => puppet,
		source => "puppet://$servername/host-puppetmaster/push/etc/puppet/manifests/site.pp", 
		before => Service["puppetmaster"] }
# workaround until facts can be part of the modules - this should work with facter 1.5 and pupet 0.24.5
	file {"/etc/puppet/facts":  mode => 550, owner => root, group => puppet,
		source => "puppet://$servername/host-puppetmaster/push/etc/puppet/facts", 
		before => Service["puppetmaster"], recurse => true, ignore => ".svn" }
	file {"/etc/puppet/tagmail.conf": ensure => present }

# clean up old puppet files
	file {["/etc/puppet/manifests/modules.pp"]: ensure => absent }
	file {["/var/lib/puppet/files","/etc/puppetrevs","/etc/puppet/.svn"]: ensure => absent, force => true }
}