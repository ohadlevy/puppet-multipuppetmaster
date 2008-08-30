class host-puppetmaster::hostgui inherits host-puppetmaster::apache {
	include kerberos::common
	Service["httpd"] { require +> File["/var/hostgui/public"] }
	# Hostgui configuration
	package {["rubygem-httpclient", "rubygem-rubyntlm", "rubygem-cmdparse", 
    "rubygem-highline", "rubygem-cgi_multipart_eof_fix", "rubygem-chronic", 
    "rubygem-memcache-client", "rubygem-ZenTest", "rubygem-packet", "rubygem-rubyforge"]:
		ensure  => installed,
		require => Yumrepo["addons"],
		before  => [Exec["Start SCGI portal"], Exec["Start backgrounDRb"]]
	}
	package {"libevent": ensure => installed}
	package {"memcached":
		ensure  => installed,
		require => [Yumrepo["addons"], Package["libevent"]],
		before  => Exec["Start SCGI portal"]
	}
	service {"memcached":
		require    => [Package["memcached"], Pushmfiles["/etc/sysconfig/memcached"]],
		enable     => true,
		ensure     => running,
		hasrestart => true,
		notify     => Exec["Start SCGI portal"]
	}
	pushmfiles {"/etc/sysconfig/memcached":
		owner   => root,
		group   => root,
		mode    => 644,
		require => Package["memcached"],
		src => "etc/sysconfig/memcached"
	}
	package {"rubygem-scgi_rails":
		ensure  => installed,
		require => [Yumrepo["addons"], Package["httpd"]],
		notify  => Exec["Patch scgi_service"],
		before  => Exec["Start SCGI portal"]
	}
	exec {"Patch scgi_service":
		command     => '/usr/bin/perl -p -i -e "s/ActiveRecord::Base.threaded_connections = false/ActiveRecord::Base.allow_concurrency = false/" /usr/lib/ruby/gems/1.8/gems/scgi_rails-0.4.3/bin/scgi_service',
		refreshonly => true,
		require     => Package["rubygem-scgi_rails"],
	}
	case $hostmode {
		"production" : { 
			$hostgui_path = "tags/hostgui"
			$hostgui_stable_version = "-1.1.0"
		}

		default : { 
			$hostgui_path = "trunk/scripts" 
			$hostgui_stable_version = undef
		}
	}
	subversion::svnserve { "hostgui$hostgui_stable_version":
		source  => "svn+ssh://svn/$hostgui_path",
		path    => "/var/hostgui",
		require => Pushmfiles["/root/.ssh/config"]
	}
	file {["/var/hostgui/public","/var/hostgui/log"]: 
		owner => apache, 
		recurse => true,
		require => Subversion::Svnserve["hostgui$hostgui_stable_version"]}

	pushmfiles {"/usr/lib/httpd/modules/mod_scgi.so":
		owner   => root,
		group   => root,
		mode    => 755,
		src     => "usr/lib/httpd/modules/mod_scgi.so.gi$gi.$architecture",
		require => Package["httpd"],
		before  => Service["httpd"]
	}
	exec {"Start SCGI portal":
		command => "/usr/bin/scgi_ctrl start",
		user 	=> "apache",
		cwd     => "/var/hostgui",
		unless  => "/bin/ps -ef|/bin/grep scgi_service|/bin/grep -v grep",
		require => [Exec["Patch scgi_service"], Subversion::Svnserve["hostgui$hostgui_stable_version"], Pushmfiles["/usr/lib/httpd/modules/mod_scgi.so"]]
	}
	append_if_no_such_line{"apache sudo":
		file    => "/etc/sudoers",
		line    => "apache ALL = NOPASSWD: /usr/sbin/puppetca",
	}
	append_if_no_such_line{"apache sudo tty":
		file    => "/etc/sudoers",
		line    => "Defaults:apache !requiretty",
	}
	# allow hostgui to add entries to autosign
	file {"/etc/puppet/autosign.conf": 
		ensure  => file,
		owner   => "apache",
		group   => "puppet",
		mode    => "644"
	}
	file {"/var/hostgui/tmp/pids":
		ensure  => directory,
		group   => apache,
		mode    => 775,
		require => Subversion::Svnserve["hostgui$hostgui_stable_version"]
	}
	exec {"Start backgrounDRb":
		cwd     => "/var/hostgui",
		command => "/var/hostgui/script/backgroundrb start",
		user    => apache,
		unless  => "/bin/ps -ef|/bin/grep backgroundrb|/bin/grep -v grep",
		require => [Subversion::Svnserve["hostgui$hostgui_stable_version"], File["/var/hostgui/tmp/pids"], Package["httpd"]]
	}
	package {"rubygem-rails": ensure => present,
		before  => [Service["puppetmaster"], Service["httpd"]],
		require => Yumrepo["addons"]
	}
}
