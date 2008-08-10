#!/usr/bin/env ruby
# Queries MySQL database for kickstart information and outputs a kickstart.
# used only a CGI script, after tftp environment has been setup already with mktftp.sh script.
# if you wish to modify any installtion options, please modify template.ks file which is being prased by this script.
#
# The script assumes the following:
# ruby and ruby-mysql are installed
# apache is configured to run this script as a cgi
# template.ks file is in the same directory as the cgi script
# mysql server is running :)
# s02 dns alias exist for nfs installtions
# puppet dns alias exist for http installations
#
# $Id: ks.cgi 1523 2008-06-28 12:45:13Z schumar $

require "erb"
require "cgi"
require "rubygems"
require "activerecord"

# directory which is mounting the tftp server directory
tftp='/var/kickstart/tftpboot/gi-install'

# default prefix for installation file location, normally should not be modfied.
path='/linux_'


# Database configuration
ActiveRecord::Base.establish_connection(
				:adapter =>  "mysql",
				:database => "production_servers",
				:username =>  "user",
				:password => "password",
				:host => "mysqlcluster"
)
class Host < ActiveRecord::Base
				belongs_to :architecture
				belongs_to :gi
				belongs_to :media
				belongs_to :puppetclass
end
class Architecture < ActiveRecord::Base
				has_many :hosts
end
class Gi < ActiveRecord::Base
				has_many :hosts
end
class Media < ActiveRecord::Base
				has_many :hosts
end
class Puppetclass < ActiveRecord::Base
				has_many :hosts
end
#===========================END OF CONFIG=======================
begin
	cgi = CGI.new()
	ip_addr = ENV['REMOTE_ADDR']
	# When using Kickstart option kssendmac (which we do) RedHat wget also sends the mac address
	# adding a "01-" in the begining as pxelinux.0 request that as the first filename in lower case
	browser = true
	if !ENV['HTTP_X_RHN_PROVISIONING_MAC_0'].nil?
		mac='01-'+ENV['HTTP_X_RHN_PROVISIONING_MAC_0'].split[1].gsub(/:/, '-').downcase
		browser = false
	end
	host = Host.find(:first, :conditions => [ "ip = \"#{ip_addr}\""])

	if host.nil? or host.ip.nil?
					cgi.out {"Sorry - no match for #{ip_addr} in our database."} if browser
	else
		media               = host.media.name.downcase
		arch                = host.architecture.name
		linux_version = host.gi.version.to_s.split('.')[0]
		linux_update  = host.gi.version.to_s.split('.')[1]
		root_pass           = host.root_pass
		grub_pass           = host.grub_pass
		archpath            = arch
		mac		    ='01-'+host.mac.gsub(/:/, '-').downcase
		diskLayout          = host.disk
		puppetclass         = host.puppetclass.name
		puppetmaster	    = host.puppetmaster
		serial              = /^(\d),(\d+)/.match(host.serial)
		if serial
			port,baud   = serial[1..2]
		else
			port,baud   = nil, nil
		end
		
		case linux_version
			when "5" then 
				linux_version = "5"
				archpath = arch
			when "4" then 
				linux_version = "4.0"
				archpath = arch + "/install"
			when "2" then 
				linux_version = "2.0"
				archpath=arch + "_ws/install"
		end
		case media
			when "nfs" then install_path = "nfs --server s02 --dir /vol/s02"+path+linux_version+"/"+archpath
			when "http" then install_path = "url --url=http://#{puppetmaster}/opt"+path+linux_version+"/"+archpath
		end
		# process template
		templatefile = File.read('template.ks')
		kickstart = ERB.new(templatefile)
		# print out cgi
		cgi.out("text/plain") {kickstart.result(binding())}
		# link tftp "reservation file" to default ==> boot from local disk
		#ipinhex=''
		#ip_addr.split('.').each do |base|
		#	ipinhex=ipinhex + base.to_i(10).to_s(16).upcase
		#end
		if !browser 
			#delete old reservation:
			#File.delete("#{tftp}/pxelinux.cfg/#{mac}") if File.exists? "#{tftp}/pxelinux.cfg/#{mac}"
			#link to boot from disk. No need for this as it falls through to "default"
			#File.symlink("default", "#{tftp}/pxelinux.cfg/#{mac}")
			#File.delete("#{tftp}/pxelinux.cfg/#{host.hostname}") if File.exists? "#{tftp}/pxelinux.cfg/#{host.hostname}"
			# Just so us poor humans can see what is going on
			#File.symlink("#{mac}","#{tftp}/pxelinux.cfg/#{host.hostname}")
		end
	end
end
