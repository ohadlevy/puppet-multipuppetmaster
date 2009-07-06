# Puppetmaster class handles the following:
# puppetmaster service 
# External nodes script 
# All customized facts
# Puppet Email logging
# RRDGraphs reports
# Padm Account
# Rpmbuild configuration on development machines

class host-puppetmaster::puppetmaster {

  include apache2::passenger
  include host-puppetmaster::apache_in_puppet
  $rackpath="/etc/puppet/rack/puppetmasterd"
  Package {require => Yumrepo["addons"]}

  package {"puppet-server": 
    ensure => "installed", 
    alias  => puppetmaster,
    before => [Service["httpd"],Exec["gen_pm_cert"]],
  }
  # RRD reports
  package { [ "rrdtool", "rubygem-RubyRRDtool" ]: ensure => present }
  # fix incorrect load path
  file {"/usr/lib/ruby/site_ruby/1.8/i386-linux/RRDtool.so": ensure => link,
    target =>  "/usr/lib/ruby/gems/1.8/gems/RubyRRDtool-0.6.0/RRDtool.so",
    require => Package["rubygem-RubyRRDtool"],
    before => Service["httpd"],
  }

  # the certificate needs to be gernated once before passanger can start
  exec{"gen_pm_cert":
    refreshonly => true,
    command => "/bin/echo", # nothing for now
    creates => "/var/lib/puppet/ssl/private_keys/$fqdn.pem",
    before => Service["httpd"],
  }

  #TODO: inherit the normal puppet settings and override
  # this template is a bit tricky, had to add code to read the manifest in order to generate the env... 
  # for more details look inside the template, and see http://projects.reductivelabs.com/issues/show/2309
  file {"/etc/puppet/puppet.conf": 
    mode => 640, owner => puppet, group => puppet, 
    content => template("host-puppetmaster/puppet.conf"),
    before  => Service["httpd"],
    require => Package["puppetmaster"],
  }

  # Apache / Passenger setup 
  file {"/etc/httpd/conf.d/puppetmaster.conf":
    content => template("host-puppetmaster/puppetmaster-vhost.conf"),
    before => Service["httpd"],
    notify => Exec["reload-apache2"],
  }
  file{["/etc/puppet/rack",$rackpath,"$rackpath/public","$rackpath/tmp"]:
    ensure => directory, owner => root, group => root, mode => 644 }

  file{"$rackpath/config.ru":
    owner => puppet, # important, this sets which user execute the pm service
    group => puppet, mode  => 644,
    content => template("host-puppetmaster/config.ru"),
    notify => Exec["restart_pm"],
    before => Service["httpd"],
  } 
  exec{"restart_pm":
    command => "/bin/touch $rackpath/tmp/restart.txt",
    refreshonly => true,
    require => File["$rackpath/tmp"],
  }
  # cant use native init script status as it find the passenger process
  service {"puppetmaster": 
    before     => Service["httpd"],
    enable     => false,
    ensure     => stopped,
    hasstatus  => false,
    pattern    => "/usr/sbin/puppetmasterd",
  }

  if $hostmode == "production" {
    file { "/var/lib/puppet/ssl/ca/serial":
      ensure => file,
      mode  => 600,
      group => "puppet",
      owner => "puppet",
    }
  }

  # Manage puppet configuration files
  file {
    "/etc/puppet":
      mode => 550, owner => root, group => puppet,
      source => "puppet:///$modulename/push/etc/puppet",
      before => Service["httpd"], recurse => true, ignore => ".svn", purge => "true";
    "/etc/puppet/tagmail.conf":
      content => $hostmode ? {
        "production" => "all: email@domain.com",
        default => "\n",
      },
      mode => 550, owner => root, group => puppet;
    ["/var/lib/puppet/yaml", "/var/lib/puppet/yaml/facts", "/var/lib/puppet/yaml/node"]:
      ensure => directory, mode => 750,
      group => "puppet", owner => "puppet";
    "/var/lib/puppet/state":
      ensure => directory,
      owner   => "puppet", group  => "puppet",
      mode   => 1755;
  }
  # make sure that the old gini-scgi is disabled
  service {"gini-scgi":
    ensure => stopped,
    enable => false,
    before => Service["httpd"],
  }

}
class host-puppetmaster::apache_in_puppet inherits apache2::ssl {
    User["apache"] { groups => "puppet" }
}
