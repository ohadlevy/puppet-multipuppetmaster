# This class instantiates a puppetmaster installation, a TFTP and  web server
class host-puppetmaster inherits host-base {
	$modulename = "host-puppetmaster"
	import "*.pp"
	import "/etc/puppet/site_modules/site_modules.pp"
	include subversion::common
	include host-puppetmaster::ssh
	include host-puppetmaster::modules
	include host-puppetmaster::puppetmaster
	
	# split the services that run on a regular puppetmaster and the puppeteer
	case $hostname {
		default: { 
			include host-puppetmaster::hostgui
			include host-puppetmaster::tftp
			include autofs::common
			include host-puppetmaster::site_modules
			include host-puppetmaster::munin
		}
    # puppeteer
		"vihla005": { 
			include host-puppetmaster::apache-puppeteer
			include host-puppetmaster::puppeteer_modules
		}
	}

	package {["ruby-mysql","ruby-ldap"]:  ensure => installed,
		require => Yumrepo["addons"]
	}
	# easier editing puppet manifests on puppet masters..
	package {"vim-enhanced": ensure => installed}
	pushmfiles {"/usr/share/vim/vim70/syntax/puppet.vim": 
		src => "usr/share/vim/vim70/syntax/puppet.vim",
		require => Package["vim-enhanced"],
		mode => 644
	}
	file { "/usr/share/vim/vim70/ftdetect": 
		ensure  => directory,
		require => Package["vim-enhanced"] 
	}
	pushmfiles {"/usr/share/vim/vim70/ftdetect/puppet.vim": 
		src => "usr/share/vim/vim70/ftdetect/puppet.vim",
		require => [File["/usr/share/vim/vim70/ftdetect"],Package["vim-enhanced"]],
		mode => 644
	}

	file {"/etc/puppet": ensure => directory, owner => "puppet", group => "puppet", mode => 550,
		before => Service["puppetmaster"] }
}
