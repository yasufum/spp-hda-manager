#!/bin/bash

CORES=4
MEMSIZE=2048
HDA=ubuntu-16.04-server-amd64.qcow2
QEMU=$HOME/dpdk-home/qemu-2.3.0/x86_64-softmmu/qemu-system-x86_64

# Don't change withou you've any reason
NOF_IF=1  # Number of NICs 
QEMU_IVSHMEM=/tmp/ivshmem_qemu_cmdline_pp_ivshmem
VM_ID=$1
RING_HDA=r${VM_ID}-${HDA}

VM_HOSTNAME=sppr${VM_ID}

# $WORKDIR is set to the directory of this script.
WORKDIR=$(cd $(dirname $0); pwd)

# Prepare image for the VM
mkdir -p ${WORKDIR}/img
HDA_INST=${WORKDIR}/img/r${VM_ID}-${RING_HDA}
if [ ${VM_ID} -eq 0 ] && [ -e ${RING_HDA} ]; then
  echo "[ring.sh] Running using original HDA"
  HDA_INST=${RING_HDA}
elif [ ! -e ${WORKDIR}/${RING_HDA} ]; then
  echo "[ring.sh] You don't have any image for runninng ring."
  echo "[ring.sh] Please install SPP and setup for ring."
  echo "[ring.sh] First, you need to install python inside VM for ansible."
  cp ${WORKDIR}/${HDA} ${WORKDIR}/${RING_HDA}
  HDA_INST=${WORKDIR}/${RING_HDA}
elif [ ! -e ${HDA_INST} ]; then 
  echo "[ring.sh] Preparing image:"
  echo "          "${HDA_INST}
  cp ${WORKDIR}/${RING_HDA} ${WORKDIR}/${HDA_INST}
  echo "[ring.sh] Change hostname to "${VM_HOSTNAME}" for convenience."
  echo "          Run hostnamectl command inside VM as following"
  echo "          $ sudo hostnamectl set-hostname "${VM_HOSTNAME}
fi

# Maximum number of NIC
# there're no reason for 5 but it's consideralbe
if [ $NOF_IF -gt 5 ] ; then
  NOF_IF=5
fi

# Setup network interfaces
NIC_OPT=""
for ((i=0; i<${NOF_IF}; i++)); do
  if [ ${VM_ID} -lt 10 ]; then
    TMP_MAC=00:AD:BE:0${VM_ID}:EF:0${i}
  else
    TMP_MAC=00:AD:BE:${VM_ID}:EF:0${i}
  fi
  TMP_NETDEV=net_r${VM_ID}_${i}
  NIC_OPT=${NIC_OPT}"-device e1000,netdev=${TMP_NETDEV},mac=${TMP_MAC} "
  NIC_OPT=${NIC_OPT}"-netdev tap,id=${TMP_NETDEV},ifname=${TMP_NETDEV},script=../ifscripts/qemu-ifup.sh "
done

# Prepare QEMU option for DPDK.
device_opt=$( cat ${QEMU_IVSHMEM} )

# For QEMU monitor
if [ ${VM_ID} -lt 10 ]; then
  TELNET_PORT=4470${VM_ID}
else
  TELNET_PORT=447${VM_ID}
fi

#
echo "[ring.sh] Boot "${VM_HOSTNAME}" with image:"
echo "          "${HDA_INST}
echo "[ring.sh] QEMU option for DPDK:"
echo "          "${device_opt}
echo "[ring.sh] telnet port: "${TELNET_PORT}

sudo ${QEMU} \
  -cpu host \
  -enable-kvm \
  -object memory-backend-file,id=mem,size=${MEMSIZE}M,mem-path=/dev/hugepages,share=on \
  -numa node,memdev=mem \
  -mem-prealloc \
  -hda ${HDA_INST} \
  -m ${MEMSIZE} \
  -smp cores=${CORES},threads=1,sockets=1 \
  ${NIC_OPT} \
  ${device_opt} \
  -monitor telnet::${TELNET_PORT},server,nowait
  #-nographic \