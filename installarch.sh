#!/usr/bin/env bash

press_any_key() {
	read -rp "Press any key to continue..."
}

main() {

	clear

	echo "Starting Arch Linux installation..."

	localectl status

	echo "Current Keymap:"
	cat /etc/vconsole.conf

	UEFI_FILE=/sys/firmware/efi/fw_platform_size

	if [ ! -f $UEFI_FILE ]; then
		echo "This installer is for UEFI systems only!"
		exit 1
	fi

	ip link

	read -rp "Make sure that the wireless network interface is enabled."

	# NETDEV=$(ip -brief link | grep BROADCAST | awk '{print $1}')
	NETDEV=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)

	read -rp "SSID for $NETDEV: " ssid
	read -rp "Passphrase: " passphrase

	iwctl --passphrase $passphrase station $NETDEV connect $ssid

	ping -c 5 archlinux.org

	timedatectl set-ntp true

	fdisk -l

	read "Press any key to partition the disk..."

	cfdisk

	echo "Format the partitions: # mkfs.ext4 /dev/root_partition"
	read -r cmd1
	command $cmd1

	echo "Mount the root volume: # mount /dev/root_partition /mnt"
	read -r cmd2
	command $cmd2

	echo "Mount the EFI system partition: # mount --mkdir /dev/efi_system_partition /mnt/efi"
	read -r cmd3
	command $cmd3

	# echo "Updating archlinux-keyring..."
	# pacman -Sy archlinux-keyring && pacman -Su

	echo "Installing essential packages... "
	pacstrap -K /mnt base linux linux-firmware e2fsprogs dhcpcd iwd neovim man-db curl bash-completion htop git

	echo "Generating fstab..."
	genfstab -U /mnt >>/mnt/etc/fstab

	vim /mnt/etc/fstab

	echo "Changing root to the new system..."
	arch-chroot /mnt

	echo "Set the time zone: # ln -sf /usr/share/zoneinfo/Region/City /etc/localtime"
	read -r cmd1
	command $cmd1

	echo "Generating /etc/adjtime"
	hwclock --systohc

	read -rp "Edit /etc/locale.gen and uncomment en_US.UTF-8 UTF-8 and other needed locales"

	vim /etc/locale.gen

	echo "Generating the locales..."
	locale-gen

	echo "Create the locale.conf(5) file, and set the LANG variable accordingly: LANG=en_US.UTF-8"
	vim /etc/locale.conf

	read -r -p "Enter hostname: " host
	echo $host >/etc/hostname

	passwd

	pacman -S grub efibootmgr os-prober amd-ucode

	read -rp "Enable detecting other OS by uncommenting GRUB_DISABLE_OS_PROBER=false in /etc/default/grub"

	vim /etc/default/grub

	echo "Install grub to the efi partition (replace /efi with the mount point of the ESP partition, ex. /efi): "
	read -rp "# grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=Arch"

	read -rp "Generate grub config: #grub-mkconfig -o /boot/grub/grub.cfg"

	read -rp "Type exit to exit the chroot environment: " cmd2
	command $cmd2

	echo "Unmounting all partitions..."
	umount -R /mnt

	echo "Finished installation."

	read -rp "Press any key to reboot."
	reboot
}

main
