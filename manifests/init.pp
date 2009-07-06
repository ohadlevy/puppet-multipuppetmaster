# This class instantiates a puppetmaster installation, a TFTP and  web server
# responsible for the Puppeteer, productive and development
# puppetmasters
class host-puppetmaster inherits host-base {
  $modulename = "host-puppetmaster"
  $puppeteer = "hostname"
   
  # Directories where modules are located
  $stable_module_path = "/etc/puppet/modules/stable"
  $testing_module_path = "/etc/puppet/modules/testing"
  $sites_module_path = "/etc/puppet/modules/sites"
  $development_module_path = "/etc/puppet/modules/development"
  $env_path = "/etc/puppet/env"

  # set some defaults
  File { owner => "root", group => "root", mode => 644 }

  import "functions.pp"
  # this file defines the environments, its in a special path as it comes from trunk!
  $envfile = "/etc/puppet/site_modules/site_modules.pp"
  import "/etc/puppet/site_modules/site_modules.pp"

  include subversion::common
  include host-puppetmaster::site_modules
  include host-puppetmaster::ssh
  include host-puppetmaster::modules
  include host-puppetmaster::puppetmaster

  
  # split the services that run on prod pm, dev pm and the puppeteer
  if ( $hostmode != "development" ) {
    include host-puppetmaster::monit
    include host-puppetmaster::munin
    include redhat::static-ip
    include host-puppetmaster::users
    include host-puppetmaster::collectd
    # setup email alerting for root
    
    if ( $hostname != $puppeteer ) {
      include host-puppetmaster::gini
      include host-puppetmaster::tftp
      include host-puppetmaster::nfs
      include host-puppetmaster::gateway
    } 
    else { # puppeteer
      include host-puppetmaster::puppeteer_modules
      file {"/var/backup-databases":
        source     => "puppet:///$modulename/push/var/backup-databases",
        mode    => 700,
        recurse => true	
      }
      cron {"backup-databases" :
        command => "/var/backup-databases/backup-databases",
        user    => root,
        minute  => 54,
        hour    => 23,
        require => File["/var/backup-databases"]
      }
    }
  } else { # all dev pm
    # we run autofs only on dev puppetmasters, this allow normal users to login, but doesnt really
    # require ldap/autofs on production servers
    include autofs::common
    include host-puppetmaster::eclipse
    include redhat::rpmbuild
  }
  # easier editing puppet manifests on puppet masters..
  package {"vim-enhanced": ensure => installed}
  file {"/usr/share/vim/vim70/syntax/puppet.vim": 
    source => "puppet:///$modulename/push/usr/share/vim/vim70/syntax/puppet.vim",
    require => Package["vim-enhanced"];
    "/usr/share/vim/vim70/ftdetect": 
    ensure  => directory,
    require => Package["vim-enhanced"]; 
   "/usr/share/vim/vim70/ftdetect/puppet.vim": 
    source => "puppet:///$modulename/push/usr/share/vim/vim70/ftdetect/puppet.vim",
    require => [File["/usr/share/vim/vim70/ftdetect"],Package["vim-enhanced"]];
  }
  
  # disableing common services, which are not needed on a puppetmaster
  service {
    ["xfs","mdmonitor","lvm2-monitor","iptables","ip6tables","bluetooth",
    "avahi-daemon","avahi-dnsconfd","conman","mcstrans","restorecond","rpcgssd","rpcidmapd"]:
    ensure => stopped,
    enable => false
  }
}
