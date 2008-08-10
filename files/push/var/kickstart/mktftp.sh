#! /bin/sh

# this script generates the tftp directory for PXE environments
# assumtion is that tftp service is running on the puppet machine and than DHCP scope options (66 and 67) has been properlly setup.
# DHCP boot server should be the puppet master
# DHCP boot path should be "gi-install/pxelinux.0"
# it is possible to overide the hostname specificed in the pxelinux files by specificing the fqdn hostname as a parameter

# syslinux package needs to be installed to copy pxelinux.0
# $Id: mktftp.sh 1649 2008-07-25 04:05:14Z levyo $

fqdn=$1
tftp="/var/kickstart/tftpboot/gi-install"

if [ "$fqdn" = "" ]; then
	fqdn=`hostname -f`
fi

mkdir -p $tftp
cd $tftp
if [ -f /usr/lib/syslinux/pxelinux.0 ]; then
	cp /usr/lib/syslinux/pxelinux.0 .
else
	echo "missing syslinux package - aborting"
	exit 1
fi
	
mkdir -p $tftp/boot
echo "Copying boot images"
for x in 2.0/i386 2.0/x86_64 4.0/i386 4.0/x86_64/ 5/i386 5/x86_64; do 
	version=`echo $x |cut -c 1`
	arch=`echo $x | cut -f 2 -d / | sed s/_ws//`
	if [ -f /opt/linux_$x/images/pxeboot/vmlinuz -a -f /opt/linux_$x/images/pxeboot/initrd.img ]; then
		cp /opt/linux_$x/images/pxeboot/vmlinuz $tftp/boot/vmlinuz-gi$version.$arch
		cp /opt/linux_$x/images/pxeboot/initrd.img $tftp/boot/initrd-gi$version.$arch
	else
		echo "ERROR: missing Kernel files, does /opt/linux_$x is mounted?, exiting..."
		exit 1
	fi
done

mkdir -p $tftp/pxelinux.cfg

cd $tftp/pxelinux.cfg
# cgi scripts needs to manage tftp reservation files
chgrp apache $tftp/pxelinux.cfg
chmod g+w  $tftp/pxelinux.cfg

cat > default << EOF
default local
timeout 20

label local
  localboot 1
EOF

echo -n "Making pxe files "
for version in 2 4 5; do
	for arch in i386 x86_64; do
		for baud in 9600 19200 38400; do
			for port in 0 1; do
				cat > gi$version-$arch-$port-$baud <<-EOF
				serial $port $baud 0
				default linux
	
				label linux
				        kernel boot/vmlinuz-gi$version.$arch
				        append initrd=boot/initrd-gi$version.$arch console=ttyS$port,$baud ks=http://$fqdn/kickstart ksdevice=eth0 network kssendmac
				EOF
				echo -n .
			done
		done
	done
done
for version in 2 4 5; do
        for arch in i386 x86_64; do
		cat > gi$version-$arch <<-EOF
		default linux
	
		label linux
		        kernel boot/vmlinuz-gi$version.$arch
		        append initrd=boot/initrd-gi$version.$arch ks=http://$fqdn/kickstart ksdevice=eth0 network kssendmac
		EOF
		echo -n .
	done
done
echo ""
echo "Done"
