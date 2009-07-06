require 'rubygems'
require 'fileutils'

module GW
  class Tftp
    # creates TFTP link to a predefine syslinux config file
    # parameter is a array ["00:11:22:33:44:55:66:77",'gi2','i386'...]
    def self.create params 
      mac, os, arch, serial = params
      return nil if mac.nil? or os.nil? or arch.nil?
      
      serial = setserial serial
      dst = "#{os}-#{arch}#{serial}"
      link=link(mac)

      FileUtils.rm_f link
      FileUtils.ln_s dst, link
    end

    # removes links created by create method
    # parmater is a mac address 
    def self.remove mac
      FileUtils.rm_f link(mac.to_s)
    end

    private
    def self.link mac
        @@tftpdir+"01-"+mac.gsub(/:/,"-").downcase
    end
    
    def self.setserial serial
      serial =~ /^(\d),(\d+)/ ? "-#{$1}-#{$2}" : nil
    end
  end

  class Puppetca
    # removes old certificate if it exists and removes autosign entry
    # parameter is the fqdn to use
    def self.clean fqdn
      command = "/usr/bin/sudo -S /usr/sbin/puppetca --clean #{fqdn}< /dev/null"
      system "#{command} >> /tmp/puppetca.log 2>&1"
      
      #remove fqdn from autosign if exists
      entries =  open("/etc/puppet/autosign.conf", File::RDONLY).readlines.collect do |l| 
        l if l.chomp != fqdn
      end
      entries.uniq!
      entries.delete(nil)
      autosign = open("/etc/puppet/autosign.conf", File::TRUNC|File::RDWR)
      autosign.write entries
      autosign.close
      return true
    end

    # add fqdn to puppet autosigns file
    # parameter is fqdn to use
    def self.sign fqdn
      autosign = open("/etc/puppet/autosign.conf", File::RDWR)
      # Check that we dont have that host already
      found = false
      autosign.each_line { |line| found = true if line.chomp == fqdn }
      autosign.puts fqdn if found == false
      autosign.close
      return true
    end

  end

  class Modules
    # trigge svn up command upon request
    # parameter is the path to update excluding the basepath, e.g. 
    # modules/sites, site_modules etc
    def self.sync repo
      basedir = "/etc/puppet/"
      command = "/usr/bin/sudo -S /usr/bin/svn --non-interactive up"
      system "#{command} #{basedir}#{repo} >> /tmp/gwlog 2>&1"
      return true
    end
    
    # starts a puppetrun which updates the env directories AND updates the modules as well.
    def refresh_envs
      command = "/usr/bin/sudo -S /usr/sbin/puppetd -o --server puppeteer --tags host-puppetmaster::site_modules host-puppetmaster::modules"
      system "#{command} >> /tmp/gwlog 2>&1"
      return true
    end
  end
end

