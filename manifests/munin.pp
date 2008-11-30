class host-puppetmaster::munin {
	case $hostname {
		default: { 
			$munin_server = "123.123.123.123" # ip addr of munin server
			include munin::client 
		}
		"munin_server": { 
			$munin_server = $ipaddress
			#extract all puppetmasters from puppet automaticilly - returns as an array to munin.conf template
      $munin_managed = template("host-puppetmaster/monitored_hosts.erb")

      include munin::host 
    }
  }
  # add some additional munin scripts (not enabled by default)
  munin::plugin { "if_eth0":
    ensure => "if_"
  }
  # add munin monitoring scripts for puppet
  munin::plugin { [puppet_mem, puppet_clients]: 
    ensure => "puppet_", 
    config => "user root",
    require => File["/usr/share/munin/plugins/puppet_"]
  }
    file {"/usr/share/munin/plugins/puppet_": 
    mode => 555, owner => root, group => root,
    source => "puppet://$servername/host-puppetmaster/push/usr/share/munin/plugins/puppet_",
    before => Service["munin-node"],
    require => Package["munin-node"]
  }
}
