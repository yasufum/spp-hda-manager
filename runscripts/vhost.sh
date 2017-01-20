#!/bin/bash

CORES=4
MEMSIZE=2048
HDA=ubuntu-16.04-server-amd64.qcow2
QEMU=$HOME/dpdk-home/qemu-2.3.0/x86_64-softmmu/qemu-system-x86_64

# Don't change withou you've any reason
VHOST_HDA=ov-${HDA}
NOF_IF=1  # Number of NICs (Don't change withou you've any reason)
VM_ID=$1

# Check if VM_ID is invalid
if [ ! ${VM_ID} ]; then
  VM_ID=1
elif [ ${VM_ID} -gt 9 ]; then
  VM_ID=9
fi

VM_HOSTNAME=spp-vhost${VM_ID}

# $WORKDIR is set to the directory of this script.
WORKDIR=$(cd $(dirname $0); pwd)

# Prepare image for the VM
mkdir -p ${WORKDIR}/img
HDA_INST=${WORKDIR}/img/v${VM_ID}-${HDA}
# If you don't have vhost's image in current dir, create it to install vhost.
if [ ! -e ${VHOST_HDA} ]; then
  echo "[vhost.sh] You don't have any image for runninng vhost."
  echo "[vhost.sh] Please install SPP and setup for vhost."
  echo "[vhost.sh] First, you need to install python inside VM for ansible."
  cp ${WORKDIR}/${HDA} ${VHOST_HDA}
  HDA_INST=${VHOST_HDA}
# If you have image in current dir, check img/ and create new image if
# instance doesn't exist.
elif [ ! -e ${HDA_INST} ]; then 
  echo "[vhost.sh] Preparing image:"
  echo "           "${HDA_INST}
  cp ${WORKDIR}/${HDA} ${HDA_INST}
fi

# Maximum number of NIC
# there're no reason for 5 but it's consideralbe
if [ $NOF_IF -gt 5 ] ; then
  NOF_IF=5
fi

# Setup network interfaces
NIC_OPT=""
for ((i=0; i<${NOF_IF}; i++)); do
  TMP_MAC=00:AD:BE:EF:A${VM_ID}:0${i}
  TMP_NETDEV=net_v${VM_ID}_${i}
  NIC_OPT=${NIC_OPT}"-device e1000,netdev=${TMP_NETDEV},mac=${TMP_MAC} "
  NIC_OPT=${NIC_OPT}"-netdev tap,id=${TMP_NETDEV},ifname=${TMP_NETDEV},script=../ifscripts/qemu-ifup.sh "
done

# Assign socket id which is used as SPP secondary id
SOCK_ID=1${VM_ID}

# For QEMU monitor
TELNET_PORT=4442${VM_ID}


#
echo "[vhost.sh] Boot "${VM_HOSTNAME}" with image:"
echo "           "${HDA_INST}
echo "[vhost.sh] telnet port: "${TELNET_PORT}

sudo ${QEMU} \
  -cpu host \
  -enable-kvm \
  -object memory-backend-file,id=mem,size=${MEMSIZE}M,mem-path=/dev/hugepages,share=on \
  -numa node,memdev=mem \
  -mem-prealloc \
  -hda ${HDA} \
  -m ${MEMSIZE} \
  -smp cores=${CORES},threads=1,sockets=1 \
  ${NIC_OPT} \
  -chardev socket,id=chr0,path=/tmp/sock${SOCK_ID} \
  -netdev vhost-user,id=net1,chardev=chr0,vhostforce \
  -device virtio-net-pci,netdev=net1 \
  -monitor telnet::${TELNET_PORT},server,nowait
#  -nographic \
#  -netdev tap,id=net0,ifname=net0,script=../ifscripts/qemu-ifup.sh \
