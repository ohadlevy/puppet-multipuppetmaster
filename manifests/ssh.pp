class host-puppetmaster::ssh inherits ssh::common {
# overide ssh config file for the puppetmaster
  $modulename = "host-puppetmaster"

  if $hostmode != "development" {
    # Allow ssh login to dev machines, restrict on production
    Staticmfiles ["/etc/ssh/sshd_config"] 
    {src => "etc/ssh/sshd_config.puppetmaster.$operatingsystem$gi", }

    # ensure a special authorized_keys for puppetmasters, not using the
    # default site settings
    File["/root/.ssh/authorized_keys"] {
      content => undef,
      source => "puppet:///$modulename/push/root/.ssh/authorized_keys",
      owner => root, group => root, mode => 440,
    }
  }

# Enable root to transparently access svn.klu as user padm
# needed for svn+ssh connections
  File { mode => 600, owner => root, group => root }
  file {
    "/root/.ssh/id_dsa.padm":
      source => "puppet:///$modulename/push/root/.ssh/id_dsa.padm",
      before => File["/root/.ssh/config"];
    "/root/.ssh/id_dsa.padm.pub": 
      source => "puppet:///$modulename/push/root/.ssh/id_dsa.padm.pub", 
      before => File["/root/.ssh/config"];
    "/root/.ssh/config": 
      source => "puppet:///$modulename/push/root/.ssh/config";
    "/var/www/.ssh": 
      ensure => directory, 
      owner  => apache, 
      group  =>apache, 
      mode   => 755,
      require => Package["httpd"]
  }
}
