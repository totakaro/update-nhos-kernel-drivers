#! /bin/sh

# NHOS Local Log Server
# By @totakaro 2021
# MIT License

# This scripts updates NHOS kernel required by AMD GPU Pro 21.10 and Nvidia 460.39 drivers

# Check root https://stackoverflow.com/a/18216122
if [ `id -u` -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Check if kernel is updated to install drivers (WIP)
uname -r | grep "5.4.3-tinycore64"
if [ $? -eq 0 ]; then
  cd /tmp
  # Update to AMD GPU Pro 21.10 
  #wget 
  #tar -Jxvf amdgpu-pro-21.10-1244864-ubuntu-18.04.tar.xz
  #cd amdgpu-pro-21.10-1244864-ubuntu-18.04
  #./amdgpu-pro-install -y --opencl=rocr,legacy,rocm --headless
  # Update to Nvidia 460.39
  #wget
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
cp -v /boot/default/initrd.gz /boot/backup.gz

# Repack the whole thing again after changes
find . | cpio -o -c -R root:root | gzip -9 > /mnt/root/boot/default/initrd.gz

# Replace fallback as well
cp -v mnt/root/boot/default/initrd.gz mnt/root/boot/fallback/initrd.gz

# Reboot
reboot
