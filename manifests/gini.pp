class host-puppetmaster::gini inherits host-puppetmaster::apache {
  Service["httpd"] { require +> File["/var/gini/public"] }

  Service {enable => true, ensure => running, hasstatus => true }
  Package {ensure => installed }
  Pushmfiles {owner => root, group => root}

  # Hostgui configuration
  package {["rubygem-httpclient", "rubygem-rubyntlm", "rubygem-cmdparse", "rubygem-highline", "rubygem-cgi_multipart_eof_fix", "rubygem-chronic", 
      "rubygem-memcache-client", "rubygem-ZenTest", "rubygem-packet", "rubygem-rubyforge", "ruby-ldap", "ruby-mysql" ]:
    require => Yumrepo["addons"],
    before  => [Service["gini-scgi"], Service["gini-backgroundrb"]]
  }
  # memcached
  package {"libevent": }
  package {"memcached":
    require => [Yumrepo["addons"], Package["libevent"]],
    before  => Service["gini-scgi"]
  }
  service {"memcached":
    require    => [User["apache"], Package["memcached"], Pushmfiles["/etc/sysconfig/memcached"]],
    notify     => Service["gini-scgi"]
  }
  pushmfiles {"/etc/sysconfig/memcached":
    mode    => 644,
    require => Package["memcached"],
    src => "etc/sysconfig/memcached"
  }
  # scgi_rails
  package {"rubygem-scgi_rails":
    require => [Yumrepo["addons"], Package["httpd"]],
    notify  => Exec["Patch scgi_service"],
    before  => Service["gini-scgi"]
  }
  exec {"Patch scgi_service":
    command     => '/usr/bin/perl -p -i -e "s/ActiveRecord::Base.threaded_connections = false/ActiveRecord::Base.allow_concurrency = false/" /usr/lib/ruby/gems/1.8/gems/scgi_rails-0.4.3/bin/scgi_service',
    refreshonly => true,
    require     => Package["rubygem-scgi_rails"],
  }
  pushmfiles {"/usr/lib/httpd/modules/mod_scgi.so":
    mode    => 755,
    src     => "usr/lib/httpd/modules/mod_scgi.so.gi$gi.$architecture",
    require => Package["httpd"],
    before  => Service["httpd"]
  }
  pushmfiles {"/etc/init.d/gini-scgi":
    mode   => 755,
    src    => "etc/init.d/gini-scgi"
  }
  pushmfiles {"/etc/init.d/gini-backgroundrb":
    mode   => 755,
    src    => "etc/init.d/gini-backgroundrb"
  }
  pushmfiles {"/etc/sysconfig/scgi":
    mode   => 600,
    src    => "etc/sysconfig/scgi"
  }

  case $hostmode {
    "production" : { 
      $gini_path = "tags/gini"
      $gini_stable_version = "-latest"
    }
    default : { 
      $gini_path = "trunk/scripts" 
      $gini_stable_version = undef
    }
  }
  subversion::svnserve { "gini$gini_stable_version":
    source  => "svn+ssh://svn.klu.infineon.com/repos/AdminToolKit/$gini_path",
    path    => "/var/gini",
    require => Pushmfiles["/root/.ssh/config"]
  }
  file {["/var/gini/public","/var/gini/log"]: 
    owner => apache, 
    recurse => true,
    require => Subversion::Svnserve["gini$gini_stable_version"]}

  append_if_no_such_line{"apache sudo":
    file    => "/etc/sudoers",
    line    => "apache ALL = NOPASSWD: /usr/sbin/puppetca",
  }
  append_if_no_such_line{"apache sudo tty":
    file    => "/etc/sudoers",
    line    => "Defaults:apache !requiretty",
  }
  # allow gini to add entries to autosign
  file {"/etc/puppet/autosign.conf": 
    ensure  => file,
    owner   => "apache",
    group   => "puppet",
    mode    => "644"
  }
  file {"/var/gini/tmp/pids":
    ensure  => directory,
    group   => apache,
    mode    => 775,
    require => Subversion::Svnserve["gini$gini_stable_version"]
  }
  file {"/tmp/puppetca.log":
    ensure  => file,
    owner   => "apache",
    group   => "puppet",
    mode    => "666",
    require => Service["gini-scgi"]
  }
  service {"gini-scgi":
    require    => [Exec["Patch scgi_service"], Subversion::Svnserve["gini$gini_stable_version"],
      Pushmfiles["/usr/lib/httpd/modules/mod_scgi.so"], Pushmfiles["/etc/init.d/gini-scgi"], 
      Pushmfiles["/etc/sysconfig/scgi"],File["/var/gini/public"],File["/var/gini/log"]],
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true
  }
  exec {"Set scgi mode":
      command => "/bin/sed -i -r -e 's/^:env: .*/:env: $hostmode/' /var/gini/config/scgi.yaml",
        unless  => "/bin/grep -E '^:env: $hostmode' /var/gini/config/scgi.yaml",
        require => Subversion::Svnserve["gini$gini_stable_version"],
    notify  => Service["gini-scgi"]
    }
    
  # backgroundrb
  service {"gini-backgroundrb":
    require    => [Subversion::Svnserve["gini$gini_stable_version"], File["/var/gini/tmp/pids"], Package["httpd"],
           Pushmfiles["/etc/init.d/gini-backgroundrb"]],
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true
  }
  package {"rubygem-rails": 
    before  => [Service["puppetmaster"], Service["httpd"]],
    require => Yumrepo["addons"]
  }
  file {["/etc/init.d/hostgui-scgi","/etc/init.d/hostgui-backgroundrb","/var/hostgui"]:
    ensure => absent,
    recurse => true,
    force  => true,
  }
}
