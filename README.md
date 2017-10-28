
Requirement
===========
* ~ 25 GB free space

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
sudo mkdir -p /github
sudo mkdir -p /kernel-build
sudo chown USER:GROUP /github
sudo chown USER:GROUP /kernel-build
cd /github
git clone https://github.com/plitc/custom_debian_kernel

cd /github/custom_debian_kernel
./custom_debian_kernel.sh stable
```

Example - create a SmartOS (8x Core Machine) LX-branded Zone for linux-kernel-build
===================================================================================

* require http://dsapid.root1.ass.de/ui/#!/configure/1c88885e-8b46-11e7-af26-8b92b4effc78
* on SmartOS (Global Zone)
```
cat <<EOF > /root/vm01.linux-kernel-build.json
{
  "brand": "lx",
  "kernel_version": "4.10.0",
  "image_uuid": "1c88885e-8b46-11e7-af26-8b92b4effc78",
  "autoboot": true,
  "alias": "linux-kernel-build",
  "hostname": "linux-kernel-build",
  "delegate_dataset": true,
  "dns_domain": "test.local",
  "resolvers": [
    "8.8.8.8",
    "8.8.4.4"
  ],
  "max_physical_memory": 8192,
  "max_swap": 2048,
  "tmpfs": 2048,
  "quota": 25,
  "cpu_cap": 800,
  "cpu_shares": 100,
  "max_lwps": 2000,
  "nics": [
    {
      "nic_tag": "admin",
      "ip": "10.1.1.100",
      "netmask": "255.255.255.0",
      "gateway": "10.1.1.1",
      "primary": true
    }
  ]
}
EOF

vmadm create -f /root/vm01.linux-kernel-build.json
```

* the LX-branded Zone (Debian 9 Based)
```
zlogin d5810180-3e51-ebfb-d93e-91d9e583e8f3
apt update
apt install git

mkdir -p /github
mkdir -p /kernel-build
cd /github
git clone https://github.com/plitc/custom_debian_kernel

cd /github/custom_debian_kernel
./custom_debian_kernel.sh stable
```

SOURCE
======
* https://www.kernel.org/
* https://debian-handbook.info/browse/en-US/stable/sect.kernel-compilation.html
* https://kernelnewbies.org/KernelBuild
* https://lists.debian.org/debian-kernel/2016/04/msg00579.html

