#!/bin/sh

check_board()
{
	# check if a board file is present
	if [ ! -f /etc/board ]; then
        	echo "No board file available - skipping."
        	return 1
	fi;

	# check content
	BOARD=$(cat /etc/board)

	if [ "$BOARD" != "confidea_g4_wdu" ]; then
        	echo "Using wrong mounting script."
        	return 1
	fi;

	return 0
}

mount_data_partition()
{
	# NOTE: assume partitions are present (done with other script)

	echo "Mount /mnt/data..."

	# create /mnt/data
	mkdir -p /mnt/data

	# only continue if data partition exists
	if [ ! -e /dev/mmcblk0p3 ]; then
        	echo "ERROR: partition mmcblk0p3 does not exist."
        	return 1
	fi;

	# make sure our mount location is empty
	rm -rf /mnt/data/*

	# try to mount data partition
	mount -o noatime,nodiratime /dev/mmcblk0p3 /mnt/data
	if [ $? -eq 0 ]; then
        	echo "Mounting OK"
        	return 0
	fi;

	echo "WARN: mounting failed - attempting to repair..."
	fsck.ext4 -p /dev/mmcblk0p3

	mount -o noatime,nodiratime /dev/mmcblk0p3 /mnt/data
	if [ $? -eq 0 ]; then
        	echo "Mounting OK"
        	return 0
	fi;

	echo "WARN: repairing failed - reformatting..."
	mkfs.ext4 -F -L "data" /dev/mmcblk0p3

	mount -o noatime,nodiratime /dev/mmcblk0p3 /mnt/data
	if [ $? -eq 0 ]; then
        	echo "Mounting OK"
        	return 0
	fi;

	echo "ERROR: not possible to create a valid data partition."
	return 1
}

prepare_data_partition()
{
	# mount root folder
	mount /mnt/data/ /home/root

	rm -rf /home/root/lost*

	# create required folders
	mkdir -m 777 -p /home/root/config
	mkdir -m 777 -p /home/root/doc
	mkdir -m 777 -p /home/root/log
	mkdir -m 777 -p /home/root/nameplates
	mkdir -m 777 -p /home/root/tmp
	mkdir -m 777 -p /home/root/update
	mkdir -m 777 -p /home/root/uftpRx
	mkdir -m 755 -p /home/root/overlays/etc/network/network
	mkdir -m 755 -p /home/root/overlays/etc/network/work

	# remove old tmp content
	rm -rf /home/root/tmp/*
	rm -rf /home/root/update/*
	rm -rf /home/root/uftpRx/*

	# mount rootfs overlays
	mount -t overlay -o lowerdir=/etc/network/,upperdir=/home/root/overlays/etc/network/network,workdir=/home/root/overlays/etc/network/work none /etc/network

	return 0
}

check_board
if [ $? -ne 0 ]; then
	exit 1
fi;

mount_data_partition
if [ $? -ne 0 ]; then
        exit 1
fi;

prepare_data_partition
if [ $? -ne 0 ]; then
        exit 1
fi;

exit 0
