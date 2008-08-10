class host-puppetmaster::munin {
	case $hostname {
		default: { 
			$munin_server = "123.123.123.123" # ip addr of munin server
			include munin::client 
		}
		"munin_server": { 
			$munin_server = $ipaddress
			#extract all puppetmasters from puppet automaticilly - returns as an array to munin.conf template
			$munin_managed = generate('/usr/bin/env', 'ruby', '-e', '%x{/bin/grep host-puppetmaster /var/lib/puppet/yaml/node/*|cut -f1 -d " "||sort|uniq}.gsub(/.*node\/(.*).....infineon.com.yaml:\n/) {|s| print "#{$1},"}.chop')

			include munin::host 
		}
	}
	munin::plugin { [puppet_mem, puppet_clients]: ensure => "puppet_", config => "user root" }
  file {"/usr/share/munin/plugins/puppet_": mode => 555, owner => root, group => root,
		source => "puppet://$servername/host-puppetmaster/push/usr/share/munin/plugins/puppet_"
	}
}
