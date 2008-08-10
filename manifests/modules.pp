class host-puppetmaster::modules {
# this class manages the module distribution to the different puppet masters world wide.
# modifing this file might replace site puppetmaster manfiests - handle with care!

# we are using module auto load, no need to specify import command per module anymore
# please note that classname must be identical to module name (e.g. class =  ssh::common, modulename = ssh)
	file {"/etc/puppet/modules": ensure => directory}
	Modules {require => File["/etc/puppet/modules"]}

	$stable_module_path = "/etc/puppet/modules/stable"
	$testing_module_path = "/etc/puppet/modules/testing"
	$sites_module_path = "/etc/puppet/modules/sites"
	
#download latest version of site modules definition files
#this is required as we want to keep it in trunk and not inside another module (which would require a retag)
	subversion::svnserve { "site_modules":
		source  => "svn+ssh://svn/repos/repo/trunk/puppet",
		path    => "/etc/puppet/site_modules",
		require => Pushmfiles["/root/.ssh/config"]
	}

#download latest version of all stable modules
	subversion::svnserve { "stable":
		source  => "svn+ssh://svn/repos/repo/tags/modules",
		path    => $stable_module_path,
		require => Pushmfiles["/root/.ssh/config"]
	}
#download latest version of all testing modules 
	subversion::svnserve { "testing":
		source  => "svn+ssh://svn/repos/repo/tags/modules",
		path    => $testing_module_path,
		require => Pushmfiles["/root/.ssh/config"]
	}
#download latest version of all sites modules
	subversion::svnserve { "sites":
		source => "svn+ssh://svn/repos/repo/trunk/puppet/modules",
		path   => $sites_module_path,
		require => Pushmfiles["/root/.ssh/config"]
	}
# directory that contains environment data
	file { "/etc/puppet/env": ensure => directory }

	case $hostmode {
		"development": {
			file { "/etc/puppet/modules/development": ensure => directory, group => puppet, mode => 665 }
			file { "/etc/puppet/modules/development/README": 
				content => "you would need to checkout manually with your username, use:\ncd /etc/puppet/modules/development ; svn co http://svn/repos/repo/trunk/puppet/modules ."
			}
		}
		default: {
	#download dev tree into each puppet to allow the usage of the development environment, this allows to try out latest trunk which can be unstable.
	# by no means this is a development area! you should build a development server if you want to build manifests.
			subversion::svnserve { "modules":
				source  => "svn+ssh://svn/repos/repo/trunk/puppet",
				path    => "/etc/puppet/modules/development",
				require => Pushmfiles["/root/.ssh/config"]
			}
		}
	}
}
