class host-puppetmaster::monit {
  # email address to send monit emails
  $monit_admin="email@domain.com"
  include monit::munin

	file {
    "/etc/monit.d/http-proxy.conf":
      content => template("host-puppetmaster/http-proxy.erb"),
		  notify  => Service["monit"];
	}
}
