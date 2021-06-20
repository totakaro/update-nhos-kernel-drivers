#! /bin/sh

# NHOS Local Log Server
# By @totakaro 2021
# MIT License

# This scripts updates NHOS kernel required by AMD GPU Pro 21.10 and Nvidia 460.39 drivers

# NHOS / Structure
# |-- [4.0K]  EFI
# |   `-- [4.0K]  BOOT
# |       `-- [ 94K]  BOOTX64.EFI
# |-- [4.0K]  apps
# |   |-- [4.0K]  default
# |   |   |-- [185M]  gminer.tcz
# |   |   |-- [4.2M]  lolminer.tcz
# |   |   |-- [ 35M]  nbminer.tcz
# |   |   |-- [4.8M]  nhm3.tcz
# |   |   `-- [168K]  nhos.tcz
# |   `-- [4.0K]  fallback
# |       |-- [185M]  gminer.tcz
# |       |-- [4.2M]  lolminer.tcz
# |       |-- [ 35M]  nbminer.tcz
# |       |-- [4.8M]  nhm3.tcz
# |       `-- [168K]  nhos.tcz
# |-- [4.0K]  boot                    <<<<< This script updates this vmlinuz and initrd (whole system compressed in 437 Mb)
# |   |-- [4.0K]  default
# |   |   |-- [ 482]  boot.cfg
# |   |   |-- [437M]  initrd.gz
# |   |   `-- [5.3M]  vmlinuz
# |   |-- [4.0K]  fallback
# |   |   |-- [ 482]  boot.cfg
# |   |   |-- [437M]  initrd.gz
# |   |   `-- [5.3M]  vmlinuz
# |   `-- [4.0K]  grub
# |       |-- [4.0K]  fonts
# |       |-- [ 931]  grub.cfg
# |       |-- [1.0K]  grubenv
# |       |-- [ 20K]  i386-pc
# |       |-- [4.0K]  locale
# |       |-- [4.0K]  themes
# |       `-- [ 20K]  x86_64-efi
# `-- [4.0K]  loader                   <<<<< Please replace Nasty GRUB, see:  https://github.com/totakaro/nhos-systemd-boot
#     |-- [4.0K]  entries
#     |   `-- [ 471]  nhos.conf
#     |-- [  42]  loader.conf
#     `-- [ 512]  random-seed
# 
# 16 directories, 22 files

# Check root https://stackoverflow.com/a/18216122
if [ `id -u` -ne 0 ]; then
  echo "Please run as root"
  #exit 1
fi

# Stop NH mining
# killall nhm3 nbminer gminer lolminer sleep nhm_monitor

# Check if kernel is updated to install drivers (WIP)
uname -r | grep "5.4.3-tinycore64"
if [ $? -eq 0 ]; then
  echo "This part is is not ready yet"
  exit
  cd /tmp
  # Stop XOrg
  init 3
  # Install required dependences to install drivers
  tce-load -wi pkg-config.tcz make.tcz gcc.tcz gcc_base-dev.tcz gcc_libs-dev.tcz gcc_libs.tcz glibc_base-dev.tcz linux-5.4_api_headers.tcz
  # Update to AMD GPU Pro 21.10 
  # wget https://github.com/totakaro/update-nhos-kernel-drivers/releases/download/v0.0.1/amdgpu-pro-21.10-1244864-ubuntu-18.04.tar.xz
  # tar -Jxvf amdgpu-pro-21.10-1244864-ubuntu-18.04.tar.xz
  # cd amdgpu-pro-21.10-1244864-ubuntu-18.04
  # chmod +x amdgpu-pro-install
  # ./amdgpu-pro-install -y --opencl=rocr,legacy,rocm --headless
  # wget https://github.com/totakaro/update-nhos-kernel-drivers/releases/download/v0.0.1/NVIDIA-Linux-x86_64-460.39.run
  # chmod +x NVIDIA-Linux-x86_64-460.39.run
  # Update to Nvidia 460.39 (ATTENTION monitor required to continue)
  # ./NVIDIA-Linux-x86_64-460.39.run
fi

# Check if the script was already executed
if [ -f /mnt/nhos/scripts.sh/vmlinuz64 ]; then
  echo "Already executed"
  echo "Delete vmlinuz64 in your script folder to execute thi script again"
  exit
fi

cd /mnt/nhos/scripts.sh

# Download Tiny Core Linux 11.X Kernel 5.4 and its modules
wget http://www.tinycorelinux.net/11.x/x86_64/archive/11.1/distribution_files/vmlinuz64
wget http://www.tinycorelinux.net/11.x/x86_64/archive/11.1/distribution_files/modules64.gz

# Mount sda3 to update the kernel
mkdir /mnt/root
mount /dev/sda3 /mnt/root

# Replace old Linux Kernel 4.19 by new Kernel 5.4.3
cp -v /mnt/nhos/scripts.sh/vmlinuz64 /mnt/root/boot/default/vmlinuz
cp -v /mnt/nhos/scripts.sh/vmlinuz64 /mnt/root/boot/fallback/vmlinuz

# Unpack initrd (The whole NHOSsystem) Nice guide here: https://access.redhat.com/solutions/24029
mkdir /tmp/initrd
cd /tmp/initrd
zcat /mnt/root/boot/default/initrd.gz | cpio -idmv

# Update Kernel modules (-u to Overwrite)
zcat /mnt/nhos/scripts.sh/modules64.gz | cpio -idmvu

# Make a backup (debug only)
cp -v /mnt/root/boot/default/initrd.gz /mnt/root/boot/backup.gz

# Repack the whole thing again after changes
find . | cpio -H newc -o -R root:root | gzip -9 > /mnt/root/boot/default/initrd.gz

# Replace fallback as well
cp -v /mnt/root/boot/default/initrd.gz /mnt/root/boot/fallback/initrd.gz

# Reboot
reboot
