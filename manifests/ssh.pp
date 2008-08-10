class host-puppetmaster::ssh inherits ssh::common {
	# overide ssh config file for the puppetmaster
	$modulename = "host-puppetmaster"

	# Allow ssh login to dev machines, restrict on production
	case $hostmode {
		"development": {}
		default: {
			Staticmfiles ["/etc/ssh/sshd_config"] 
				{src => "etc/ssh/sshd_config.puppetmaster.$operatingsystem$gi", }
		}
	}
	# ensure a special authorized_keys for puppetmasters, not using the
	# default site settings
	File["/root/.ssh/authorized_keys"] {content => template("$modulename/authorized_keys.erb")}

# Enable root to transparently access svn.klu as user padm
# needed for svn+ssh connections
	pushmfiles {"/root/.ssh/id_dsa.padm":
		src => "root/.ssh/id_dsa.padm", mode => 600, before => Pushmfiles["/root/.ssh/config"] }
	pushmfiles {"/root/.ssh/id_dsa.padm.pub": 
		src => "root/.ssh/id_dsa.padm.pub", mode => 600, before => Pushmfiles["/root/.ssh/config"] }
	pushmfiles {"/root/.ssh/config": src => "root/.ssh/config", mode => 600 }
}

