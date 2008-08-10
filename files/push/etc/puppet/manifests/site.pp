import "/etc/puppet/site_modules/sitedef.pp"

case $hosttype {
# we don't want the local site setup running on our puppetmasters...
	"host-puppetmaster": { }
	default: {
		include $sitename
	}
}
