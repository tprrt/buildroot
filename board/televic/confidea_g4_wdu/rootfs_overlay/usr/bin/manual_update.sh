#!/bin/sh

# confidea g4 wdu manual upgrade script

UPG_LOC="/home/root/update"
ERROR_LOG="/tmp/progress.log"

BOARD_TYPE="unknown"
CONTAINER_TYPE="unknown"

BOARD=$(cat /etc/board)

if [ "$BOARD" = "confidea_g4_wdu" ] ||
   [ "$BOARD" = "confidea_g4_wdu_golden" ]
then
	BOARD_TYPE="0xF640"
	CONTAINER_TYPE="0xF6B0"
fi;

create_log()
{
	printf "" >> $ERROR_LOG
}

print_progress()
{
	printf "Update: PROGRESS %s\n" "$1" >> $ERROR_LOG
	printf "Update: PROGRESS %s\n" "$1"
}

print_error()
{
	printf "Update: ERROR    %s\n" "$1" >> $ERROR_LOG
	printf "Update: ERROR    %s\n" "$1"
}

print_success()
{
	printf "Update: DONE\n" >> $ERROR_LOG
	printf "Update: DONE\n"
}

install_update_file()
{
	print_progress "install $1"

	# extract file
	print_progress "extract $UNAME"
	tar -xf $UPG_LOC/update/$UNAME -C $UPG_LOC/update

	# search filename for the update
	FNAME=$(jq -r '.files[0].name' $UPG_LOC/update/sys_contents.txt)
	FCHECKSUM=$(jq -r '.files[0].md5' $UPG_LOC/update/sys_contents.txt)
	FSCRIPT=$(jq -r '.upgscript' $UPG_LOC/update/sys_contents.txt)

	print_progress "filename: $FNAME"
	print_progress "checksum: $FCHECKSUM"
	print_progress "script  : $FSCRIPT"

	# check if requested files exists
	if [ ! -f $UPG_LOC/update/$FNAME ]
	then
		print_error "This upgrade misses a required file."
		return 1
	fi

	if [ ! -f $UPG_LOC/update/$FSCRIPT ]
	then
		print_error "This upgrade misses an upgrade script."
		return 1
	fi

	# calculate the md5
	CHECKSUMCALC=$(md5sum $UPG_LOC/update/$FNAME | awk -e '{print $1}')
	print_progress "calculated: $CHECKSUMCALC"

	if [ $FCHECKSUM != $CHECKSUMCALC ]
	then
		print_error "The update file is corrupt."
		return 1
	fi

	print_progress "execute upgrade script: $UPG_LOC/update/$FSCRIPT"
	cd $UPG_LOC/update
	$UPG_LOC/update/$FSCRIPT -i $UPG_LOC/update/$FNAME -p $ERROR_LOG

	if [ $? -eq 0 ]
	then
		print_success
		return 0
	fi

	print_error "upgrade script returned failure"
	return 1
}

parse_update_file()
{
	print_progress "extract $1"

	rm -rf $UPG_LOC/update
	mkdir -p $UPG_LOC/update
	tar -xf $1 -C $UPG_LOC/update

	if [ ! -e $UPG_LOC/update/contents.txt ]
	then
		print_error "No contents.txt file found"
		return 1
	fi

	# check for container tuf
	for TYPE in $(jq -r '.files[] | .target' $UPG_LOC/update/contents.txt); do

		if [ "$TYPE" = "$CONTAINER_TYPE" ]
		then
			print_progress "Found container type: $TYPE"

			# search filename for the confidea G4 WDU update
			UNAME=$(jq -r ".files[] | select(.target==\"$CONTAINER_TYPE\") | .name" $UPG_LOC/update/contents.txt)

			# check if requested file exists
			if [ -f $UPG_LOC/update/$UNAME ]
			then
				# file exist -> move file & restart
				mv $UPG_LOC/update/$UNAME $1
				parse_update_file $1
				return $?
			fi

			print_progress "Container type: $TYPE - missing file"
		fi

		if [ "$TYPE" = "$BOARD_TYPE" ]
		then
			print_progress "Found board type: $TYPE"

			# search filename for the update
			UNAME=$(jq -r ".files[] | select(.target==\"$BOARD_TYPE\") | .name" $UPG_LOC/update/contents.txt)

			# check if requested file exists
			if [ -f $UPG_LOC/update/$UNAME ]
			then
				# file exist -> update
				install_update_file $UPG_LOC/update/$UNAME
				return $?
			fi

			print_progress "Board type: $TYPE - missing file"
		fi

		echo "done"
	done;

	print_error "This upgrade does not contain a Confidea G4 WDU specific part."
	return 1
}

SIZE=0
OLD_SIZE=0
search_update_file()
{
	if [ ! -e $1 ]
	then
		print_error "$1 isn't present"
		return 1
	fi

	print_progress "found $1, starting update"

	parse_update_file $1
	retval=$?

	OLD_SIZE=0
	SIZE=0

	return $retval
}

create_log

if [ $# -eq 0 ]
then
	print_error "Need update file as argument"
	exit 1
fi

search_update_file $1
exit $?
