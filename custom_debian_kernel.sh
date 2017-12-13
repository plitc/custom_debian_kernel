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

#// FUNCTION:
check_environment() {
   PLATFORM=$(uname -a | grep -c "BrandZ")
   if [ "$PLATFORM" = "1" ]
   then
      #// for SmartOS Environments
      echo "detect: LX-branded Zone..."
      if [ -z "$(ls -A /boot | grep config-`uname -r`)" ]
      then
         echo "[$(printf "\033[1;33mFAILED\033[0m\n")] /boot is empty, copy a kernel config before! (the /boot/config-VERSION file must match the LX Brandz kernel string)"
         exit 1
      fi
   fi
}

#// FUNCTION:
fetch_info() {
   GETLATESTMAINVERSION=$(curl -s https://www.kernel.org/feeds/kdist.xml | grep "$1" | grep "title" | sed 's/title/###/g' | head -n 1 | tr '###' '\n' | egrep "$1" | sed 's/[^[0-9\.\-]]*//g' | tr '.' '\n' | head -n1)
   GETLATESTVERSION=$(curl -s https://www.kernel.org/feeds/kdist.xml | grep "$1" | grep "title" | sed 's/title/###/g' | head -n 1 | tr '###' '\n' | egrep "$1" | sed 's/[^[0-9\.\-]]*//g')
   GETCPUCORES=$(nproc)
}

#// FUNCTION:
requirements() {
   (sudo mkdir -p /kernel-build) & spinner $!
   checkhard mkdir /kernel-build

   (sudo apt-get autoclean) & spinner $!
   checksoft apt-get autoclean

   (sudo apt-get clean) & spinner $!
   checksoft apt-get clean

   (sudo apt-get update) & spinner $!
   checksoft apt-get update

   (sudo apt-get install -y libncurses5-dev gcc make git exuberant-ctags bc libssl-dev) & spinner $!
   checkhard apt-get install the BUILD ENVIROMENT

   #/(sudo apt-get install -y dpkg-dev time curl gnupg dirmngr gnupg-agent gnupg-l10n gnupg-utils gpg-wks-client gpg-wks-server gpgconf gpgsm gpgv gnupg2) & spinner $!
   (sudo apt-get install -y dpkg-dev time curl gnupg dirmngr gnupg-agent gnupg-l10n gpgsm gpgv) & spinner $!
   checkhard apt-get install necessary tools
}

#// FUNCTION:
download() {
if [ -e /kernel-build/linux-"$GETLATESTVERSION".tar.xz ]
then
   : # dummy
else
   (curl -o /kernel-build/linux-"$GETLATESTVERSION".tar.xz https://cdn.kernel.org/pub/linux/kernel/v"$GETLATESTMAINVERSION".x/linux-"$GETLATESTVERSION".tar.xz) & spinner $!
   checkhard downloaded the kernel source package
   (curl -o /kernel-build/linux-"$GETLATESTVERSION".tar.sign https://cdn.kernel.org/pub/linux/kernel/v"$GETLATESTMAINVERSION".x/linux-"$GETLATESTVERSION".tar.sign) & spinner $!
   checkhard downloaded the kernel source package sign file
fi
}

#// FUNCTION:
pre_extract() {
if [ -e /kernel-build/linux-"$GETLATESTVERSION" ]
then
   (rm -rf /kernel-build/linux-"$GETLATESTVERSION") & spinner $!
   checkhard remove the old kernel directory
   (unxz /kernel-build/linux-"$GETLATESTVERSION".tar.xz) & spinner $!
   checkhard pre_extract the kernel source
else
   (unxz /kernel-build/linux-"$GETLATESTVERSION".tar.xz) & spinner $!
   checkhard pre_extract the kernel source
fi
}

#// FUNCTION:
verify(){
   gpg2 --verify /kernel-build/linux-"$GETLATESTVERSION".tar.sign
   if [ $? -eq 2 ]
   then
      gpg2 --verify /kernel-build/linux-"$GETLATESTVERSION".tar.sign > /tmp/linux-"$GETLATESTVERSION".tar.sign.output 2>&1
      GETKEYID=$(egrep "RSA|DSA" /tmp/linux-"$GETLATESTVERSION".tar.sign.output | tr ' ' '\n' | tail -n 1)
      gpg2 --keyserver hkp://keys.gnupg.net --recv-keys "$GETKEYID"
      checkhard import missing key
   fi
   #// check again
   gpg2 --verify /kernel-build/linux-"$GETLATESTVERSION".tar.sign
   checkhard verify the archive against the signature
}

#// FUNCTION:
extract() {
if [ -e /kernel-build/linux-"$GETLATESTVERSION" ]
then
   (tar -xaf /kernel-build/linux-"$GETLATESTVERSION".tar.xz -C /kernel-build) & spinner $!
   checkhard extract the kernel source
else
   (tar -xaf /kernel-build/linux-"$GETLATESTVERSION".tar.xz -C /kernel-build) & spinner $!
   checkhard extract the kernel source
fi
}

#// FUNCTION:
configure() {
   (cp /boot/config-`uname -r`* /kernel-build/linux-"$GETLATESTVERSION"/.config) & spinner $!
   checkhard copy the current kernel config

   cd /kernel-build/linux-"$GETLATESTVERSION" && make menuconfig
   checkhard make menuconfig
}

#// FUNCTION:
build() {
   #// https://lists.debian.org/debian-kernel/2016/04/msg00579.html
   (sed -i 's/.*CONFIG_SYSTEM_TRUSTED_KEYS.*/CONFIG_SYSTEM_TRUSTED_KEYS=""/g' /kernel-build/linux-"$GETLATESTVERSION"/.config) & spinner $!
   checkhard modify kernel config settings so that custom kernels will get modules signed by a one-time key
   cd /kernel-build/linux-"$GETLATESTVERSION" && time make -j"$GETCPUCORES" deb-pkg LOCALVERSION=-custom KDEB_PKGVERSION=$(make kernelversion)-1
   checkhard kernel build
   ls -allt /kernel-build | grep ".deb" | egrep -v "tar.gz" | head -n 5
}

#// FUNCTION:
info() {
   ### ### ###
   echo ""
   echo "next steps:"
   echo "sudo dpkg -i /kernel-build/linux-headers-$GETLATESTVERSION-custom_$GETLATESTVERSION-1_amd64.deb"
   echo "sudo dpkg -i /kernel-build/linux-image-$GETLATESTVERSION-custom_$GETLATESTVERSION-1_amd64.deb"
   echo "sudo dpkg -i /kernel-build/linux-firmware-image-$GETLATESTVERSION-custom_$GETLATESTVERSION-1_amd64.deb"
   echo "sudo update-grub"
   echo "reboot"
   ### ### ###
}

#// RUN

### // stage0 ###

checkdebiandistribution

case "$1" in
### ### ### ### ### ### ### ### ###
'stable')
### stage1 // ###

check_environment
fetch_info stable
requirements
download
pre_extract
verify
extract
configure
build
info

echo "" # dummy
printf "\033[1;32mcuston_debian_kernel finished.\033[0m\n"
### // stage1 ###
   ;;
'mainline')
### stage1 // ###

check_environment
fetch_info mainline
requirements
download
pre_extract
verify
extract
configure
build
info

echo "" # dummy
printf "\033[1;32mcuston_debian_kernel finished.\033[0m\n"
### // stage1 ###
   ;;
### ### ### ### ### ### ### ### ###
*)
printf "\033[1;31mWARNING: custom_debian_kernel is experimental and its not ready for production. Do it at your own risk.\033[0m\n"
echo "" # usage
echo "usage: $0 { stable | mainline }"
;;
esac

### ### ### PLITC // ### ### ###
exit 0
# EOF
