# This class handles the variuos gateway functionallities (TFTP, PuppetCA, Puppetrun etc)
class host-puppetmaster::gateway {
  File{ mode => 440, owner => root, group => apache, before => Service["httpd"] }

  file{
    "/etc/httpd/conf.d/gateway.conf":
      content => template("$modulename/gateway.conf.erb"),
      notify => Exec["reload-apache2"];
    ["/var/www/gateway","/var/www/gateway/lib"]:
      ensure => directory;
    "/var/www/gateway/gateway.cgi":
      mode => 550,
      source => "puppet:///$modulename/push/var/www/gateway/gateway.cgi";
    "/var/www/gateway/lib/gw.rb":
      source => "puppet:///$modulename/push/var/www/gateway/lib/gw.rb";
  }      
}
