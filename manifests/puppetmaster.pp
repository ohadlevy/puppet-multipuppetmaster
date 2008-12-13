# Puppetmaster class handles the following:
# puppetmaster service 
# External nodes script 
# All customized facts
# Puppet Email logging
# RRDGraphs reports
# Rpmbuild configuration on development machines

class host-puppetmaster::puppetmaster {

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

	group {"puppet": ensure => present, gid => 101} 
	user {"padm":
		ensure   => present,
		gid      => puppet,
		home     => "/var/lib/puppet/files",
		shell    => "/bin/bash",
		password => '',
		require  => Group["puppet"],
	}

  file {"/etc/puppet/puppet.conf": mode => 640, owner => puppet, group => puppet, 
        content => template("host-puppetmaster/puppet.conf"),
        before  => Service["puppetmaster"],
        require => Package["puppetmaster"],
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
        before      => Service["puppetmaster"]
      }
      file { "/var/lib/puppet/ssl/ca/serial":
        ensure => file,
        mode  => 600,
        group => "puppet",
        owner => "puppet",
      }
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
			file {"/etc/sysconfig/puppetmaster": 
				mode    => 644, 
				content => template("host-puppetmaster/puppetmaster.sysconfig"),
				notify  => Service["puppetmaster"],
				require => Package["puppetmaster"], 
				before  => Service["puppetmaster"]
			}
		}
	}
	service {"puppetmaster": 
		require    => [Package["puppetmaster"],Package["rubygem-mongrel"]],
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
# workaround until facts can be part of the modules - this should work with facter 1.5 and pupet 0.24.5
	file {"/etc/puppet/facts":  mode => 550, owner => root, group => puppet,
		source => "puppet://$servername/host-puppetmaster/push/etc/puppet/facts", 
		before => Service["puppetmaster"], recurse => true, ignore => ".svn", purge => "true" }
	file {"/etc/puppet/manifests":  mode => 550, owner => root, group => puppet,
		source => "puppet://$servername/host-puppetmaster/push/etc/puppet/manifests", 
		before => Service["puppetmaster"], recurse => true, ignore => ".svn", purge => "true" }
	file {"/etc/puppet/tagmail.conf": ensure => present }

	file { ["/var/lib/puppet/yaml", "/var/lib/puppet/yaml/facts", "/var/lib/puppet/yaml/node"]:
    ensure => directory,
    group => "puppet",
    owner => "puppet",
  }
  file { "/var/lib/puppet/state":
    ensure => directory,
    owner   => "puppet",
    group  => "puppet",
    mode   => 1755,
  }
}
