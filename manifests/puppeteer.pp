class host-puppetmaster::puppeteer_modules {

# this file defines the modules used in the puppeeteer which configures the puppetmasters

# please note that this variables also exists in host-puppetmaster::modules class, I didnt find a way to access the variables in both classes, 
# therefor, if you change this below, make sure they match also to the definitions in modules.pp
  $stable_module_path = "/etc/puppet/modules/stable"
  $testing_module_path = "/etc/puppet/modules/testing"
  $sites_module_path = "/etc/puppet/modules/sites"

  module_dir { "/etc/puppet/env/global_puppetmaster":}

##### Stable service modules ##### 
  modules { "PP-host-base": module => "host-base", site => "global_puppetmaster", type => "services", version => "0.12" }
  modules { "PP-sudo": module => "sudo", site => "global_puppetmaster", type => "services", version => "0.1" }
  modules { "PP-ssh": module => "ssh", site => "global_puppetmaster", type => "services", version => "0.1" }
  modules { "PP-sendmail": module => "sendmail", site => "global_puppetmaster", type => "services", version => "0.14" }
  modules { "PP-ldap": module => "ldap", site => "global_puppetmaster", type => "services", version => "0.11" }
  modules { "PP-redhat": module => "redhat", site => "global_puppetmaster", type => "services", version => "0.12" }
  modules { "PP-autofs": module => "autofs", site => "global_puppetmaster", type => "services", version => "0.1" }
  modules { "PP-apache2": module => "apache2", site => "global_puppetmaster", type => "services", version => "0.1" }
  modules { "PP-subversion": module => "subversion", site => "global_puppetmaster", type => "services", version => "0.11" }
  modules { "PP-syslog-ng": module => "syslog-ng", site => "global_puppetmaster", type => "services", version => "0.11" }
  modules { "PP-monit": module => "monit", site => "global_puppetmaster", type => "services", version => "0.1" }
  modules { "PP-munin": module => "munin", site => "global_puppetmaster", type => "services", version => "0.1" }
####  stable host types modules #####
  modules { "PP-puppetmaster": site => "global_puppetmaster", module => "host-puppetmaster", version => "0.21" }
}
