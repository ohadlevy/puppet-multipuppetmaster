# this class manages the module distribution to the different puppet masters world wide.
# modifying this file might replace site puppetmaster manifests - handle with care!

# we are using module auto load, no need to specify import command per module anymore
# please note that classname must be identical to module name (e.g. class =  ssh::common, modulename = ssh)
class host-puppetmaster::modules {
  file {"/etc/puppet/modules": ensure => directory}
  Modules {require => File["/etc/puppet/modules"]}
  Subversion::Svnserve { require => File["/root/.ssh/config"]}

  subversion::svnserve {
    #download latest version of site modules definition files
    #this is required as we want to keep it in trunk and not inside another module 
    "site_modules":
      source => "svn+ssh://svn/repos/AdminToolKit/trunk/puppet",
      path   => "/etc/puppet/site_modules";
    "stable":
      source => "svn+ssh://svn/repos/AdminToolKit/tags/modules",
      path   => $stable_module_path;
    "testing":
      source => "svn+ssh://svn/repos/AdminToolKit/tags/modules",
      path   => $testing_module_path;
    "sites":
      source => "svn+ssh://svn/repos/AdminToolKit/trunk/puppet/modules",
      path  => $sites_module_path;
  }
# directory that contains actual puppet environments
  file { $env_path: 
    ensure => directory,
    recurse => true, 
    purge => true, 
    force => true,
  }

  case $hostmode {
    "development": {
      file { 
        $development_module_path: ensure => directory, group => puppet, mode => 665;
        "$development_module_path/README": 
          content => "you would need to checkout manually with your username, use:\ncd /etc/puppet/modules/development ; svn co https://svn/repos/AdminToolKit/trunk/puppet/modules .\n\nNotice: You may use --no-auth-cache option if you would not like subversion to cache your password in your home Dir\n",
          replace => no
      }
    }
    default: {
#download dev tree into each puppet to allow the usage of the development environment, this allows to try out latest trunk which can be unstable.
# by no means this is a development area! you should build a development server if you want to build manifests.
      subversion::svnserve { "development":
        source  => "svn+ssh://svn/repos/AdminToolKit/trunk/puppet",
        path    => $development_module_path,
      }
    }
  }
}
