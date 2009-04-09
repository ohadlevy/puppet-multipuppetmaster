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

  import "*.pp"
  import "/etc/puppet/site_modules/site_modules.pp"
  include subversion::common
  include host-puppetmaster::ssh
  include host-puppetmaster::modules
  include host-puppetmaster::puppetmaster
  include host-puppetmaster::site_modules
  include host-puppetmaster::users
  include autofs::common
  
  # split the services that run on a regular puppetmaster and the puppeteer
  case $hostname {
    default: { 
      case $hostmode {
        default: {
          include host-puppetmaster::gini
          include host-puppetmaster::tftp
       }
        "development": {
          include host-puppetmaster::gini_disable 
        }
      } 
    }
    $puppeteer: {
      include host-puppetmaster::apache-puppeteer
      include host-puppetmaster::puppeteer_modules
      pushmfiles {"/var/backup-databases":
        src     => "var/backup-databases",
        owner   => "root", group => "root",
        mode    => 700,
        recurse => true	
      }
      cron {"backup-databases" :
        command => "/var/backup-databases/backup-databases",
        user    => root,
        minute  => 54,
        hour    => 23,
        require => Pushmfiles["/var/backup-databases"]
      }
    }
  }
  case $hostmode {
    "development": {
      include host-puppetmaster::eclipse
    }
    default: { 
      include host-puppetmaster::monit
      include host-puppetmaster::munin
      include redhat::static-ip
    }
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

  file {"/etc/puppet": ensure => directory, 
    owner => "puppet", group => "puppet", mode => 550,
    before => Service["puppetmaster"]
  }
  
  # disableing common services, which are not needed on a puppetmaster
  service { ["xfs","mdmonitor","lvm2-monitor","iptables","ip6tables","bluetooth"]:
    ensure => stopped,
    enable => false
  }
}
