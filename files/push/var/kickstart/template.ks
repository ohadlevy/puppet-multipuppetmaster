<% # template kickstart file to use with kickstart CGI script %>
<% # this file is being used to generate the kickstart, change with care. %>
<% # ohad.levydomain %>

install
<%= install_path %> 
lang en_US.UTF-8
<% if version != "5"   %>langsupport --default en_US.UTF-8 en_GB.UTF-8 en_US.UTF-8<% end %>
<% if version == "2.0" %>mouse generic3usb --device input/mice<% end %>
<% if version != "2.0" %>selinux --disabled <% end %>
keyboard us
skipx
network --device eth0 --bootproto dhcp
rootpw --iscrypted <%= root_pass %> 
firewall --disabled
authconfig --useshadow --enablemd5
timezone Europe/Vienna
<% if puppetclass == "hybrid-client" %>
bootloader --location=mbr --append="nofb quiet rhgb idle=poll iommu=memaper vga=791 splash=quiet selinux=0 pci=nommconf" --md5pass=<%= grub_pass %>
%include /tmp/diskpart.cfg
<% elsif port %>
bootloader --location=mbr --append="nofb quiet splash=quiet console=ttyS<%=port%>,<%=baud%>" --md5pass=<%= grub_pass %> 
zerombr yes
clearpart --all --initlabel
<%= diskLayout %>
<% else %>
bootloader --location=mbr --append="nofb quiet rhgb splash=quiet" --md5pass=<%= grub_pass %> 
zerombr yes
clearpart --all --initlabel
<%= diskLayout %>
<% end %>
skipx
<% if puppetclass != "hybrid-client" %>text<% end %>
reboot

%packages <% if version != "5" %> --resolvedeps <% end %>
<% if version == "5" %>
@core
@base
@ruby
<% end %>
<% if version == "4.0" %>
device-mapper-multipath
<% end %>

<% if puppetclass == "hybrid-client" %>
%pre
#if any ntfs partition exits on the machine its a new fat client, therefore we delete everything! :)
#if a fat partition exist we check if it has an isc image on it, if not we delete it as well
#in any case all Linux partitions are formatted.

FAT_P=`fdisk -l |grep -i fat |awk '{print $1}' |awk -F/ '{print $3}'`
if [ "$FAT_P" = "" ]; then
        VMWARE_P_OPT=" --fstype vfat --size 1 --grow"
else
        VMWARE_P_OPT=" --onpart $FAT_P --fstype vfat --size 1 --grow"
fi
NTFS_P=`fdisk -l |grep -i ntfs`
if [ "$NTFS_P" = "" ]; then
        CLEARPART_OPT="--linux"
        if [ "$FAT_P" = "" ]; then
                VMWARE_P_OPT=" --fstype vfat --size 1 --grow"
        else
                mkdir /tmp/vmware
                mount -t vfat /dev/$FAT_P /tmp/vmware
                if [ -f /tmp/vmware/vmware/isc.vmx ]; then
                        VMWARE_P_OPT=" --onpart $FAT_P --noformat"
                fi
                umount /tmp/vmware
                rmdir /tmp/vmware
        fi
else
        CLEARPART_OPT="--all"
fi

cat <<EOF > /tmp/diskpart.cfg
zerombr yes
clearpart $CLEARPART_OPT
part / --fstype ext3 --size 9000
part /boot --fstype ext3 --size 100 --asprimary
part /vmware $VMWARE_P_OPT
part swap --recommended
EOF
<% end %>

%post
logger "Starting anaconda postinstall ..."

#changing to VT 3 that we can see whats going on....
/usr/bin/chvt 3

# Who are we and where, according to the DNS
fqdn=`nslookup \`ifconfig eth0|egrep "inet "|cut -f2 -d:|cut -f1 -d" "\`|egrep name|cut -f 2 -d=|cut -f2 -d" "|sed -e "s/.$//"`
domain=`echo $fqdn|egrep -o "(...\domain)\$"`
site=`echo $fqdn | cut -c 1-3`

# We need the goldenimage volume to install the rpms with yum from nfs but if it does not exits it will fall back to yum.kludomain

<% if media == "nfs" %>
# Mount goldenimage and arrange for it to be present when the system is rebooted for the first puppet run
# For some reason the FQDN of s02 is required in Bristol
mkdir -p /opt<%= path %><%= version %>
mount -o ro,nolock,rsize=32768 s02:/vol/s02<%= path %><%= version %> /opt<%= path %><%= version %>
echo "s02:/vol/s02<%= path %><%= version %>  /opt<%= path %><%= version %>   nfs     ro,nocto,hard,intr,rsize=32768,wsize=32768      0       0" >> /etc/fstab
<% end %>

# and update all the base packages from the updates repository
yum -t -y -e 0 --enablerepo addons upgrade

# and add the puppet package
yum -t -y -e 0 --enablerepo addons install puppet

# Activate some desirable puppet features
cat > /etc/puppet/puppet.conf << EOF
[main]
    vardir = /var/lib/puppet
    logdir = /var/log/puppet
    rundir = /var/run/puppet
    ssldir = \$vardir/ssl
    pluginsource = puppet://$server/plugins
    environments = $site,development,${site}_test
[puppetd]
    factsync = true
    report = true
    listen = true
    graph  = true
    environment = $site
EOF

# The puppet service will not start without this file unless it is in test/debug mode. Its contents are updated later in the build process.
/bin/touch /etc/puppet/namespaceauth.conf

# Setup puppet to run on system reboot
/sbin/chkconfig --level 345 puppet on

# Disable autofs. Puppet starts it after reconfiguring it correctly
/sbin/chkconfig --level 345 autofs off

# Disable most things. Puppet will activate these if required.
/sbin/chkconfig --level 345 gpm off
/sbin/chkconfig --level 345 sendmail off
/sbin/chkconfig --level 345 cups off
<% if version == "5" %>
/sbin/chkconfig --level 345 yum-updatesd off
<% end %>

# Run puppet just to get the client certificate; this works with DHCP, but I haven't tested it if the IP info is given statically. 
# And obviously, it's not a very good idea for disconnected installs. In that case, puppet will run when the machine is rebooted after the install. 
# The reason I pull the cert during installation is so that I can turn autosign for this machine on while it's being provisioned and then off again once
# provisioning is finished. 
# Don't forget to run 'puppetca -c CLIENT' on the puppetmaster before reprovisioning the client Run puppet, just to get the certs; 
# the actual config update happens on the next reboot

hostname $fqdn
puppetmaster=`host -t txt $fqdn|perl -n -e '/puppetmaster=([A-z0-9\.]+)/; print "$1\n"'`
echo "$puppetmaster" > /tmp/puppetmaster

# This first puppet run creates the client's ssl datastructures. 
# It cannot connect until it has its rootCA bundle applied

# OK. Lets clarify, for non-puppetmasters this is the sequence
# 1) puppetmaster MUST have autosign or pre-created certificates
# 2) puppet negotiates its own key via raw tcp
# 3) receives its own signed certificate + the CA certificate
# 4) opens an SSL connection but this fails.
# 5) Updates its CA bundle with the rootCA pem
# 6) further attempts, after the reboot, will succeed
# Note that puppetmasters will succeed at step 4 so we add
# a --tags no_such_tag to make it skip the run

# A client's master can be configured in its txt record but falls back to "puppet" if 
# an entry "puppetmaster=<string>" is not present

if [ -n "$puppetmaster" ] 
then
	echo "PUPPET_SERVER=$puppetmaster" >> /etc/sysconfig/puppet
	# puppet.conf gets overwritten on the first puppet run, but why not
	echo "server = $puppetmaster" >> /etc/puppet/puppet.conf
	/usr/sbin/puppetd --test --fqdn $fqdn --tags no_such_tag --server $puppetmaster
else
	puppetmaster="puppet"
	/usr/sbin/puppetd --test --fqdn $fqdn --tags no_such_tag
fi

# We need a mechanism for propagating the CA root certificate.
# We use kickstart because this needs to be in place before
# puppet will work.

# This is the CA for vihla005. It is self signed.
echo "-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
" >> /var/lib/puppet/ssl/certs/ca.pem

echo "Updated the certificate chain"
sleep 2

# when NIS option is set in DHCP, hostname FQDN is the NIS domainname, using fqdn instead 	 	 
echo PUPPET_EXTRA_OPTS=--fqdn=$fqdn >>/etc/sysconfig/puppet 

# Inform the build system that we are done. Best do this before possibly breaking the network!
wget -O /dev/null http://$puppetmaster/host/built\?hostname=$fqdn
wget -O /dev/null http://$puppetmaster:3000/host/built\?hostname=$fqdn

# Deal with vmware install here as it cannot be done under puppet
# The vmware configuration disconnects the puppetmaster!!
if dmidecode | grep -qi VMware
then
	yum -t -y -e 0 --enablerepo addons install VMwareTools
	touch /etc/running_inside_vmware
	<% if version == "4.0" and arch == "i386" %>
	/usr/bin/vmware-config-tools.pl -d
	<% else %>
	/bin/echo "\n" | /usr/bin/vmware-config-tools.pl -p
	<% end %>
fi	
