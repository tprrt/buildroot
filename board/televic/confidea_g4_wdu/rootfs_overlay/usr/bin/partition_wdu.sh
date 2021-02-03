#!/bin/sh

# check if a board file is present
if [ ! -f /etc/board ]
then
	echo "No board file available - skipping."
	return 1
fi

# check content
BOARD=$(cat /etc/board)

if [ "$BOARD" != "confidea_g4_wdu" ]
then
	echo "Using wrong partition script."
	return 1
fi

echo "Checking partitions..."

# check if all required partitions are available
if [ -e /dev/mmcblk0p1 ] &&
   [ -e /dev/mmcblk0p2 ] &&
   [ -e /dev/mmcblk0p3 ]
then
	echo "ok."
	exit 0
fi;

# check if the eMMC chip is detected
if [ ! -e /dev/mmcblk0 ]; then
	echo "ERROR: no eMMC detected."
	echo "No eMMC detected" > /tmp/emmc.txt
	exit 1
fi;

echo "Creating partition table"
(
	echo o # Create a new empty DOS partition table
	echo n # Add a new partition - upgrade 1 / 1G
	echo p # Primary partition
	echo 1 # Partition number
	echo 16      # start sector
	echo 2097167 # last sector
	echo n # Add a new partition - upgrade 2 / 1G
	echo p # Primary partition
	echo 2 # Partition number
	echo 2097168 # start sector
	echo 4194319 # last sector
	echo n # Add a new partition - data / rest of disk
	echo p # Primary partition
	echo 3 # Partition number
	echo 4194320 # start sector
	echo         # last sector: accept default
	echo w # write to disk
) | fdisk -u /dev/mmcblk0

reboot

exit 0
