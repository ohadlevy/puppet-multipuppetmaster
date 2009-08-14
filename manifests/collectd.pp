class host-puppetmaster::collectd {
  include collectd::client
  # run the collectd in listen mode and provide basic web interface on the puppeteer
  if $hostname == $puppeteer {
    include collectd::server
  } else {
    collectd::network{"collectd": server => "1.2.3.4" }
    # memcache currently runs on all puppet servers, but not on the puppeteer
    collectd::plugin{"memcached":
      lines => ['Host "127.0.0.1"','Port "11211"'],
    }
  }
  collectd::plugin{["cpu","memory","load","disk","processes","swap","users"]:}
  collectd::plugin{"interface":
    lines => ['Interface "eth0"','IgnoreSelected false'],
  }
  collectd::plugin{"df":
    lines => ['FSType "ext3"','IgnoreSelected false'],
  }
  collectd::plugin{"tcpconns":
    lines => ['ListeningPorts false','LocalPort "22"','LocalPort "8140"','LocalPort "80"','LocalPort "443"','LocalPort "8443"'],
  }
  package{"collectd-apache": ensure => installed,
    notify => Service["collectd"],
  }
  collectd::plugin{"apache":
    lines => ['Instance "apache"','URL "http://localhost:8666/server-status?auto"'],
  }
  collectd::plugin{"filecount":
    lines => [
      ['<Directory "/var/lib/puppet/yaml/node">',
        'Instance "known puppet clients"','</Directory>'],
      ['<Directory "/var/lib/puppet/yaml/node">',
        'Instance "Pupppet Clients in the last 5 minutes"','MTime "-5m"','</Directory>'],
      ['<Directory "/var/lib/puppet/yaml/node">',
        'Instance "Pupppet Clients in the last 24 hours"','MTime "-1d"','</Directory>'],
      ],
  }
  collectd::plugin{"syslog":
    lines => ['LogLevel "info"'],
  }
}
