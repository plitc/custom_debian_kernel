#!/bin/sh

### LICENSE - (BSD 2-Clause) // ###
#
# Copyright (c) 2017, Daniel Plominski (Plominski IT Consulting)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
### // LICENSE - (BSD 2-Clause) ###

### ### ### PLITC // ### ### ###

### stage0 // ###
DEBIAN=$(grep -s "ID=" /etc/os-release | egrep -v "VERSION" | sed 's/ID=//g')
DEBVERSION=$(grep -s "VERSION_ID" /etc/os-release | sed 's/VERSION_ID=//g' | sed 's/"//g')
DEBTESTVERSION=$(grep -s "PRETTY_NAME" /etc/os-release | awk '{print $3}' | sed 's/"//g' | grep -c "stretch/sid")
MYNAME=$(whoami)

PRG="$0"
##/ need this for relative symlinks
   while [ -h "$PRG" ] ;
   do
         PRG=$(readlink "$PRG")
   done
DIR=$(dirname "$PRG")
#
ADIR="$PWD"

#// FUNCTION: spinner (Version 1.0)
spinner() {
   local pid=$1
   local delay=0.01
   local spinstr='|/-\'
   while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
         local temp=${spinstr#?}
         printf " [%c]  " "$spinstr"
         local spinstr=$temp${spinstr%"$temp"}
         sleep $delay
         printf "\b\b\b\b\b\b"
   done
   printf "    \b\b\b\b"
}

#// FUNCTION: clean up tmp files (Version 1.0)
cleanup() {
   rm -rf /etc/lxc-to-go/tmp/*
}

#// FUNCTION: run script as root (Version 1.0)
checkrootuser() {
if [ "$(id -u)" != "0" ]; then
   echo "[ERROR] This script must be run as root" 1>&2
   exit 1
fi
}

#// FUNCTION: check debian based distributions (Version 1.0)
checkdebiandistribution() {
case $DEBIAN in
debian|linuxmint|ubuntu|devuan|raspbian)
   : # dummy
   ;;
*)
   : # dummy
   echo "[ERROR] Plattform = unknown"
   exit 1
   ;;
esac
}

#// FUNCTION: check state (Version 1.0)
checkhard() {
if [ $? -eq 0 ]
then
   echo "[$(printf "\033[1;32m  OK  \033[0m\n")] '"$@"'"
else
   echo "[$(printf "\033[1;31mFAILED\033[0m\n")] '"$@"'"
   sleep 1
   exit 1
fi
}

#// FUNCTION: check state without exit (Version 1.0)
checksoft() {
if [ $? -eq 0 ]
then
   echo "[$(printf "\033[1;32m  OK  \033[0m\n")] '"$@"'"
else
   echo "[$(printf "\033[1;33mFAILED\033[0m\n")] '"$@"'"
   sleep 1
fi
}

#// FUNCTION: check state hidden (Version 1.0)
checkhiddenhard() {
if [ $? -eq 0 ]
then
   return 0
else
   checkhard "$@"
   return 1
fi
}

#// FUNCTION: check state hidden without exit (Version 1.0)
checkhiddensoft() {
if [ $? -eq 0 ]
then
   return 0
else
   checksoft "$@"
   return 1
fi
}


GETLATESTVERSION=$(curl -s https://www.kernel.org/feeds/kdist.xml | grep "stable" | grep "title" | sed 's/title/###/g' | head -n 1 | tr '###' '\n' | egrep "stable" | sed 's/[^[0-9\.\-]]*//g')
GETCPUCORES=$(nproc)

requirements() {
   (sudo mkdir -p /kernel-build) & spinner $!
   checksoft mkdir /kernel-build

   (sudo apt-get autoclean) & spinner $!
   checksoft apt-get autoclean

   (sudo apt-get clean) & spinner $!
   checksoft apt-get clean

   (sudo apt-get update) & spinner $!
   checksoft apt-get update

   (sudo apt-get install -y libncurses5-dev gcc make git exuberant-ctags bc libssl-dev) & spinner $!
   checkhard apt-get install the BUILD ENVIROMENT
}

download() {
if [ -e /kernel-build/linux-"$GETLATESTVERSION".tar.xz ]
then
   : # dummy
else
   (curl -o /kernel-build/linux-"$GETLATESTVERSION".tar.xz https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-"$GETLATESTVERSION".tar.xz) & spinner $!
   checksoft downloaded the kernel source package
fi
}

extract() {
   (tar -xaf /kernel-build/linux-"$GETLATESTVERSION".tar.xz -C /kernel-build) & spinner $!
   checksoft extracted the kernel source
}

configure() {
   (cp /boot/config-`uname -r`* /kernel-build/linux-"$GETLATESTVERSION"/.config) & spinner $!
   checksoft copy the current kernel config

   cd /kernel-build/linux-"$GETLATESTVERSION" && make menuconfig
   checkhard make menuconfig
}

build() {
   #// https://lists.debian.org/debian-kernel/2016/04/msg00579.html
   (sed -i 's/.*CONFIG_SYSTEM_TRUSTED_KEYS.*/CONFIG_SYSTEM_TRUSTED_KEYS=""/g' /kernel-build/linux-"$GETLATESTVERSION"/.config) & spinner $!
   checkhard modify kernel config settings so that custom kernels will get modules signed by a one-time key
   cd /kernel-build/linux-"$GETLATESTVERSION" && make -j"$GETCPUCORES" deb-pkg LOCALVERSION=-plitc KDEB_PKGVERSION=$(make kernelversion)-1
   checkhard kernel build
   ls -allt /kernel-build/linux-"$GETLATESTVERSION" | grep "*.deb"
}

#// RUN

checkdebiandistribution

requirements
download
extract
configure
build

### ### ### PLITC // ### ### ###
exit 0
# EOF
