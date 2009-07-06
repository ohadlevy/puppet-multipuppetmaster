#! /usr/bin/env ruby
require 'lib/gw.rb'
require 'cgi'

@@tftpdir= "/var/kickstart/tftpboot/gi-install/pxelinux.cfg/"
ginihost = "172.28.110.101"

cgi=CGI.new

# allow access only to ginihost
if ENV['REMOTE_ADDR'] != ginihost
  cgi.out("status" => "FORBIDDEN", "connection" => "close") {""}
  exit
end

# ensure that we have some parameters
if cgi.has_key?("action") and cgi.has_key?("params")
  action = cgi["action"]
  params = cgi.params["params"]
else
  cgi.out("status" => "BAD_REQUEST", "connection" => "close") {""}
  exit
end

# lookup API class and execute

execute=eval("GW::#{action.capitalize}(params)")

unless execute.nil?
  cgi.out("status" => "OK", "connection" => "close") {""}
else
  cgi.out("status" => "NOT_IMPLEMENTED", "connection" => "close") {""}
end
