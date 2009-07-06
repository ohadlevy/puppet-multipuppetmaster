class host-puppetmaster::gini inherits apache2::ssl {
  $ginipath="/var/gini"
  include apache2::passenger

  Package {ensure => installed }
  File {owner => root, group => root}

# Gini configuration
# Gini 1.3+ requires rubygems > 1.3
  package { "rubygems": ensure => "1.3.1-1.el5", require => Yumrepo["addons"] }
  package {["rubygem-rails","rubygem-httpclient", "rubygem-rubyntlm", "rubygem-cmdparse", "rubygem-highline", 
    "rubygem-cgi_multipart_eof_fix", "rubygem-chronic", "rubygem-memcache-client", "rubygem-ZenTest", 
    "rubygem-packet", "rubygem-rubyforge", "ruby-ldap", "ruby-mysql", "rubygem-curb", "libevent",
    "rubygem-rmagick", "jasper", "jasper-devel", "ImageMagick", "ImageMagick-devel", "rubygem-gruff" ]:
      require => Yumrepo["addons"],
      before  => [Service["httpd"], Service["gini-backgroundrb"]]
  }

  file{"/etc/httpd/conf.d/gini.conf":
    content => template("host-puppetmaster/gini-vhost.conf"),
    mode => 644, notify => Exec["reload-apache2"],
  }

  package {"memcached":
    require => [Yumrepo["addons"], Package["libevent"]],
    before  => Service["httpd"]
  }
  service {"memcached":
    require => [User["apache"], Package["memcached"], File["/etc/sysconfig/memcached"]],
    notify  => Exec["restart_gini"]
  }
  file { "/etc/sysconfig/memcached":
    mode    => 644,
    require => Package["memcached"],
    source => "puppet:///host-puppetmaster/push/etc/sysconfig/memcached";
  }
  munin::plugin {"memcached" : 
    ensure => "memcached", 
    config => "env.HOST localhost\nenv.port 11211",
    require => File["/usr/share/munin/plugins/memcached"]
  }
  file {
    "/usr/share/munin/plugins/memcached": 
      mode => 555,
      source => "puppet:///host-puppetmaster/push/usr/share/munin/plugins/memcached",
      before => Service["munin-node"],
      require => Package["munin-node"];
    "/etc/monit.d/memcached.conf":
      source  => "puppet:///host-puppetmaster/push/etc/monit.d/memcached.conf",
      before  => Service["monit"];
  }

  exec{"restart_gini":
    command => "/bin/touch $ginipath/tmp/restart.txt",
    refreshonly => true
  }

# Gini code automatic distribution though subversion
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
    source  => "svn+ssh://svn/repos/AdminToolKit/$gini_path",
    path    => "$ginipath",
    require => File["/root/.ssh/config"],
    notify  => [Exec["restart_gini"],Service["gini-backgroundrb"]],
    before  => Service["httpd"],
  }
  file {
    "$ginipath/config/environment.rb":
      owner => apache, # super important, this defines the users which runs Gini
      before => Service["httpd"];
    "$ginipath/public":
      owner => apache, recurse => true, mode => 0440,
      require => Subversion::Svnserve["gini$gini_stable_version"],
      before => Service["httpd"];
    "$ginipath/log":
      owner => apache, recurse => true, mode => 0640,
      ignore => ".svn",
      before => Service["httpd"];
  }

  append_if_no_such_line{
    "apache sudo":
      file    => "/etc/sudoers",
      line    => "apache ALL = NOPASSWD: /usr/sbin/puppetca";
    "apache sudo tty":
      file    => "/etc/sudoers",
      line    => "Defaults:apache !requiretty";
  }
# allow gini to add entries to autosign
  file {
    "/etc/puppet/autosign.conf": 
      ensure => file, owner => "apache", group => "puppet", mode => "644";
    "$ginipath/tmp/pids":
      ensure => directory, owner => apache, group => apache,
      mode   => 775, require => Subversion::Svnserve["gini$gini_stable_version"];
    "/tmp/puppetca.log":
      ensure => file, owner => "apache", group  => "puppet",
      mode   => "664", require => Service["httpd"];
  }
  
# background queue service
  file {"/etc/init.d/gini-backgroundrb":
    mode   => 755,
    source => "puppet:///host-puppetmaster/push/etc/init.d/gini-backgroundrb"
  }

  service {"gini-backgroundrb":
    require    => [Subversion::Svnserve["gini$gini_stable_version"], File["$ginipath/tmp/pids"], 
               Package["httpd"], File["/etc/init.d/gini-backgroundrb"]],
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true
  }
}
