class host-puppetmaster::tftp {
	include redhat::xinetd
# Kickstart configuration is now via hostgui, no more using kickstart cgi

	package {"tftp-server":    ensure => installed}
	package {"syslinux":       ensure => installed}
	file{"/var/kickstart": ensure => directory, mode => 755}
	pushmfiles{"/var/kickstart/mktftp.sh":   src => "var/kickstart/mktftp.sh",
		mode => 755, notify  => Exec["Build tftpboot dir"] }
	file {"/var/kickstart/tftpboot":    ensure => directory, require => Pushmfiles["/var/kickstart/mktftp.sh"] }
	file {"/var/kickstart/tftpboot/gi-install":    ensure => directory, require => Pushmfiles["/var/kickstart/mktftp.sh"] }
	file {"/var/kickstart/tftpboot/gi-install/pxelinux.cfg": ensure => directory,  group => apache, mode => 775 }
	exec {"Build tftpboot dir":
		command => "/var/kickstart/mktftp.sh $fqdn",
		require => [Pushmfiles["/var/kickstart/mktftp.sh"], Service["autofs"]],
		refreshonly => true
	}
	pushmfiles {"/etc/xinetd.d/tftp":
		src  => "etc/xinetd.d/tftp",
		mode => 644,
		require => [Package["tftp-server"], Exec["Build tftpboot dir"], Package["xinetd"]],
		notify  => Service["xinetd"]
	}
}

