#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

## Prevent initramfs updates from trying to run grub and lilo.
## https://journal.paul.querna.org/articles/2013/10/15/docker-ubuntu-on-rackspace/
## http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=594189
export INITRD=no
mkdir -p /etc/container_environment
echo -n no > /etc/container_environment/INITRD

## Enable Ubuntu Universe, Multiverse, and deb-src for main.
sed -i 's/^#\s*\(deb.*main restricted\)$/\1/g' /etc/apt/sources.list
sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list
sed -i 's/^#\s*\(deb.*multiverse\)$/\1/g' /etc/apt/sources.list
apt-get update

## Fix some issues with APT packages.
## See https://github.com/dotcloud/docker/issues/1024
dpkg-divert --local --rename --add /sbin/initctl
ln -sf /bin/true /sbin/initctl

## Replace the 'ischroot' tool to make it always return true.
## Prevent initscripts updates from breaking /dev/shm.
## https://journal.paul.querna.org/articles/2013/10/15/docker-ubuntu-on-rackspace/
## https://bugs.launchpad.net/launchpad/+bug/974584
dpkg-divert --local --rename --add /usr/bin/ischroot
ln -sf /bin/true /usr/bin/ischroot

# apt-utils fix for Ubuntu 16.04
$minimal_apt_get_install apt-utils

## Install HTTPS support for APT.
$minimal_apt_get_install apt-transport-https ca-certificates

## Install add-apt-repository
$minimal_apt_get_install software-properties-common

## Upgrade all packages.
apt-get dist-upgrade -y --no-install-recommends -o Dpkg::Options::="--force-confold"

## Fix locale.
case $(lsb_release -is) in
  Ubuntu)
    $minimal_apt_get_install language-pack-ru-base language-pack-en-base
    ;;
  Debian)
    $minimal_apt_get_install locales locales-all
    ;;
  *)
    ;;
esac
locale-gen --purge en_US.UTF-8 ru_RU.UTF-8
update-locale --reset LANG=ru_RU.UTF-8 LC_ALL=ru_RU.UTF-8 LANGUAGE=ru_RU:en
echo -n ru_RU.UTF-8 > /etc/container_environment/LANG
echo -n ru_RU.UTF-8 > /etc/container_environment/LC_CTYPE

## Fix timezone
export TZ=Europe/Moscow
$minimal_apt_get_install tzdata
echo $TZ > /etc/timezone && ln -sf /usr/share/zoneinfo/$TZ /etc/localtime

## Some packages
$minimal_apt_get_install ssh-import-id bash-completion mc htop strace lsof bzip2 xz-utils
