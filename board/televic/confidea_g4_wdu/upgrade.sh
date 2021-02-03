#!/bin/sh

# confidea g4 wdu upgrade script

XPRE="wdu_upgrade >>"
ROOTFS_FILE="rootfs.tar.xz"
PROGRESS_FILE=""
BOARD_TYPE="unknown"

STEPS_TOTAL=4
UPGRADE_STEP=0

usage()
{
cat << EOF
    usage: $0 options

    This script writes confidea g4 wdu images to hardware

    OPTIONS:
       -h      show this help text
       -r/-i   update rootfs <filename>
       -p      path to progress file
EOF
}

print_error()
{
	UPGRADE_STEP=$STEPS_TOTAL
	printf "%s ERROR	step %s/%s - %s\n" "$XPRE" "$UPGRADE_STEP" "$STEPS_TOTAL" "$1" >> $PROGRESS_FILE
	exit 1
}

print_progress()
{
	printf "%s PROGRESS step %s/%s - %s\n" "$XPRE" "$UPGRADE_STEP" "$STEPS_TOTAL" "$1" >> $PROGRESS_FILE
}

print_progress_done()
{
	printf "%s PROGRESS step %s/%s - %s\n" "$XPRE" "$UPGRADE_STEP" "$STEPS_TOTAL" "$1" >> $PROGRESS_FILE
}

upgrade_wdu()
{
	STEPS_TOTAL=4
	UPGRADE_STEP=0

	# Note: an update will change the application env variable in u-boot
	# The number is stored to a temporary file (removed on reboot)
	# to make sure we don't accidently update the wrong location
	# in case a second update is done, without rebooting.
	if [ ! -e /tmp/application ]
	then
		fw_printenv -n application > /tmp/application
	fi
	APPLICATION=$(cat /tmp/application)

	# currently first partition?
	if [ $APPLICATION -ne 1 ]; then
		ROOTFS_PARTITION="/dev/mmcblk0p1"
		ROOTFS_LABEL="rootfsA"
		APPLICATION=1
	else
		ROOTFS_PARTITION="/dev/mmcblk0p2"
		ROOTFS_LABEL="rootfsB"
		APPLICATION=2
	fi;

	if [ -z "$ROOTFS_PARTITION" ]
	then
		print_error "Board is missing the required partition."
		exit 1
	fi

	UPGRADE_STEP="1"
	print_progress "Formatting: ${ROOTFS_PARTITION}"
	mkfs.ext4 -F -L ${ROOTFS_LABEL} ${ROOTFS_PARTITION} &> /dev/null

	UPGRADE_STEP="2"
	print_progress "Installing new rootfs"
	rm -rf /tmp/rootfs
	mkdir -p /tmp/rootfs
	mount -o noatime,nodiratime,data=journal ${ROOTFS_PARTITION} /tmp/rootfs

	tar -xf ${ROOTFS_FILE} -C /tmp/rootfs
	echo "$BOARD_TYPE" > /tmp/rootfs/etc/board
	sync
	umount /tmp/rootfs

	UPGRADE_STEP="3"
	print_progress "Update uboot variables: application $APPLICATION"
	fw_setenv application $APPLICATION
	fw_setenv bootdelay 0
	sync

	UPGRADE_STEP="4"
	print_progress_done "Update finished"
}

while getopts "hr:c:i:p:s:" OPTION
do
	case $OPTION in
		h)
			usage
			exit 0
			;;
		c|s)
			# present for backwards compatibility
			;;
		r|i)
			ROOTFS_FILE=$OPTARG
			;;
		p)
			PROGRESS_FILE=$OPTARG
			;;
		-|*)
			;;
	esac
done

# no progress file? -> use tty
if [ "$PROGRESS_FILE" = "" ]
then
    PROGRESS_FILE=$(tty)
fi

print_progress "File: ${ROOTFS_FILE}"

# check board type
if [ -e /etc/board ]
then
	BOARD_TYPE=$(cat /etc/board)
fi

print_progress "Boardtype: $BOARD_TYPE"

if [ "$BOARD_TYPE" = "confidea_g4_wdu" ] ||
   [ "$BOARD_TYPE" = "confidea_g4_wdu_golden" ]
then
	BOARD_TYPE="confidea_g4_wdu"
	upgrade_wdu
	exit 0
fi

print_error "This upgrade can't be installed on this board."
exit 1
