### What is this?

Setup tools for creating and running VMs for SPP.


### How to use

#### (1) Get ISO file

This tools support Ubuntu (I've tested only 16.04, but 14.04 possibly run).
Download ISO file form Ubuntu's web page.
URLs are listed in [iso/iso-list.txt](iso/README.md).


#### (2) Create VM image

Put ISO file you downloaded into iso/ directory to be refered
the from script.

Then, move to iso/ and edit, run `img_creator.sh` script.
There are four params in the script.
  - HDA: name of image file of VM.
  - ISO: name of ISO you downloaded.
  - FORMAT: format type of image file. qcow2 is better if you use KVM.
  - HDASIZE: size of image file, 10G is adequate for ubuntu server.

Run the script as following.

```
$ bash img_creator.sh
```

After run the script, QEMU opens another window for installation.
So, you install Ubuntu by following the instructions.

Finally, shutdown OEMU's window after finished installation by clicking close button of the window.
If you choose restart inside the window without close, QEMU attempts installation again.


#### (3) Setup QEMU

Before run VM using this tool, you have to setup specialized qemu
for running DPDK with IVSHMEM.
Currently it's included in repository of
previous version of SPP (https://github.com/garogers01/soft-patch-panel).

##### 3-1 Get source

Create a directory for download and get source from the repository.

```
$ mkdir [WORK_DIR]
$ cd  [WORK_DIR]
$ git clone https://github.com/garogers01/soft-patch-panel.git
```

##### 3-2 Compile

Move to `[WORK_DIR]` and run make command for compilation.

```
$ cd [WORK_DIR]/qemu-2.3.0
$ ./configure --enable-kvm --target-list=x86_64-softmmu --enable-vhost-net
$ make
```

It would take a while to compile QEMU.
Compiled executable `qemu-system-x86_64` is placed in `[WORK_DIR]/qemu-2.3.0/x86_64-softmmu/`.


#### (4) Run VM

Now you can run VM of the image you created by using QEMU command.
However, you had better to use run scripts as following than input command and options by hand.

First, copy image file into runscript/ which you created by running `iso/img_creator.sh` in section (2).
Then, you edit `runscript/run-vm.py` to identify your image from the script.
You also edit the location of qemu executable.
Each of them are defined as following params in the scripts.
  - QEMU: location of specialized QEMU's exec file.
  - HDA: image file you created.

You are ready to run VM.
But before run the script, you have to consider which type of SPP interfaces
you use, or don't use.
SPP supports two types of interface, `ring` and `vhost` to communicate with VMs.
Please refer [setup guide](http://dpdk.org/browse/apps/spp/tree/docs/setup_guide.md) of SPP for details.

You have to give a type with `-t` option.
There three types.
`none` doesn't use SPP interface.
  - ring
  - vhost
  - none
To refer help message, run the script with `-h` option.

```
$ ./run-vm.py -h
usage: run-vm.py [-h] [-i VIDS] [-t TYPE] [-c CORES] [-m MEM]

Run SPP and VMs

optional arguments:
  -h, --help            show this help message and exit
  -i VIDS, --vids VIDS  VM IDs
  -t TYPE, --type TYPE  Interface type ('ring','vhost' and 'none')
  -c CORES, --cores CORES
                        Number of cores
  -m MEM, --mem MEM     Memory size
```
