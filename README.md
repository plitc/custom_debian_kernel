Requirement
===========
* ~ 20 GB free space

Usage
=====
```
╭─root at daniel in /github/custom_debian_kernel on master✘✘✘ using
╰─± ./custom_debian_kernel.sh
WARNING: custom_debian_kernel is experimental and its not ready for production. Do it at your own risk.

usage: ./custom_debian_kernel.sh { stable | mainline }
```

Example
=======
```
sudo mkdir /kernel-build
sudo chown USER:GROUP /kernel-build
cd /kernel-build
git clone https://github.com/plitc/custom_debian_kernel

cd /kernel-build/custom_debian_kernel
./custom_debian_kernel.sh stable
```

SOURCE
======
* https://www.kernel.org/
* https://debian-handbook.info/browse/en-US/stable/sect.kernel-compilation.html
* https://kernelnewbies.org/KernelBuild
* https://lists.debian.org/debian-kernel/2016/04/msg00579.html

