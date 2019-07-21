#!/bin/bash

RAM=${1:-12288}

echo 'Starting libvirtd'
/usr/sbin/libvirtd &
/usr/sbin/virtlogd &

# Wait for 10 seconds for libvirt sockets to be created
TIMEOUT=$((SECONDS+10))
while [ $SECONDS -lt $TIMEOUT ]; do
    if [ -S /var/run/libvirt/libvirt-sock ]; then
       break;
    fi
done

echo 'Setting /dev/kvm permissions'
chown -f root:kvm /dev/kvm
chmod 666 /dev/kvm

if virsh dominfo cvp; then
  echo 'CVP VM already exists'
  virsh undefine cvp
else
  echo 'CVP VM does not exist yet'
fi

echo 'Generating answer CDROM'
cat << EOF > /cvp/answers.yaml
version: 2
common: 
   default_route: 192.168.122.1
   dns: [ 1.1.1.1 ]
   ntp: [ 0.fedora.pool.ntp.org, 1.fedora.pool.ntp.org ]
   device_interface: eth0       
   cluster_interface: eth0

node1:
   hostname: cvp.lab
   interfaces:
      eth0:
         ip_address: 192.168.122.100
         netmask: 255.255.255.0
EOF
/cvp/geniso.py -y /cvp/answers.yaml -p cvpadmin -o /cvp/

#echo 'Creating disk snapshots'
#qemu-img create -f qcow2 -b /cvp/disk1.qcow2 /cvp/overlay_disk1.qcow2
#qemu-img create -f qcow2 -b /cvp/disk2.qcow2 /cvp/overlay_disk2.qcow2

echo 'Generating libvirt XML'
/cvp/generateXmlForKvm.py -n cvp \
--device-bridge virbr0 -i /cvp/cvpTemplate.xml -o result.xml \
-x /cvp/overlay_disk1.qcow2 -y /cvp/overlay_disk2.qcow2 \
-c /cvp/node1-cvp.iso -b $RAM -p 2 \
-e /usr/libexec/qemu-kvm

echo 'Starting CVP VM'
virsh define result.xml
virsh start cvp

echo 'Setting iptables rules'
iptables -I FORWARD -o virbr0 -d 192.168.122.100 -j ACCEPT
iptables -t nat -I PREROUTING -p tcp --dport 443 ! -s 192.168.122.100 -j DNAT --to 192.168.122.100:443
iptables -t nat -I PREROUTING -p tcp --dport 9910 ! -s 192.168.122.100 -j DNAT --to 192.168.122.100:9910



echo 'All tasks completed. Entering sleeping loop...'

# Sleep and wait for the kill
trap : TERM INT; sleep infinity & wait
