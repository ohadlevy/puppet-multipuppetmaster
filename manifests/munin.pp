class host-puppetmaster::munin {
  case $hostname {
    default: { 
      $munin_server = "1.2.3.4"
      $munin_apache_ports = "80 443 8140"
      include munin::client-apache
    }
    $puppeteer: { 
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
  munin::plugin {"memcached" : 
    ensure => "memcached", 
    config => "HOST localhost\nport 11211",
    require => File["/usr/share/munin/plugins/memcached"]
  }
  file {"/usr/share/munin/plugins/puppet_": 
    mode => 555, owner => root, group => root,
    source => "puppet:///host-puppetmaster/push/usr/share/munin/plugins/puppet_",
    before => Service["munin-node"],
    require => Package["munin-node"]
  }
  file {"/usr/share/munin/plugins/memcached": 
    mode => 555, owner => root, group => root,
    source => "puppet:///host-puppetmaster/push/usr/share/munin/plugins/memcached",
    before => Service["munin-node"],
    require => Package["munin-node"]
  }
}
