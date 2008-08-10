class host-puppetmaster::puppeteer_modules {

# this file defines the modules used in the puppeeteer which configures the puppetmasters

# please note that this variables also exists in host-puppetmaster::modules class, I didnt find a way to access the variables in both classes, 
# therefor, if you change this below, make sure they match also to the definitions in modules.pp
	$stable_module_path = "/etc/puppet/modules/stable"
	$testing_module_path = "/etc/puppet/modules/testing"
	$sites_module_path = "/etc/puppet/modules/sites"

	file { "/etc/puppet/env/production": ensure => directory, 
		before => Subversion::Svnserve["stable"] }
	file { "/etc/puppet/env/testing": ensure => directory, 
		before => Subversion::Svnserve["testing"] }

##### Stable service modules ##### 
	modules { "PP-host-base": module => "host-base", site => "production", type => "services", version => "0.11" }
	modules { "PP-sudo": module => "sudo", site => "production", type => "services", version => "0.1" }
	modules { "PP-ssh": module => "ssh", site => "production", type => "services", version => "0.1" }
	modules { "PP-sendmail": module => "sendmail", site => "production", type => "services", version => "0.13" }
	modules { "PP-ldap": module => "ldap", site => "production", type => "services", version => "0.1" }
	modules { "PP-redhat": module => "redhat", site => "production", type => "services", version => "0.11" }
	modules { "PP-autofs": module => "autofs", site => "production", type => "services", version => "0.1" }
	modules { "PP-apache2": module => "apache2", site => "production", type => "services", version => "0.1" }
	modules { "PP-mysql": module => "mysql", site => "production", type => "services", version => "0.1" }
	modules { "PP-subversion": module => "subversion", site => "production", type => "services", version => "0.11" }
	modules { "PP-syslog-ng": module => "syslog-ng", site => "production", type => "services", version => "0.1" }
##### site specific module #####
	modules { "sin": module => "singapore", site => "production", type => "site" }
####  stable host types modules #####
	modules { "PP-puppetmaster": site => "production", module => "host-puppetmaster", version => "0.12" }

##### testing modules #####
#	modules { "PP-test-host-base": module => "host-base", site => "testing", type => "testing", version => "0.12" }
}
