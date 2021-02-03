#!/bin/sh
# pre-image.sh for televic regular/upgrade build
# 2016, Theo Debrouwere <t.debrouwere@televic.com>
# 2019, Arno Messiaen <a.messiaen@televic.com>

echo "Add /etc/version to build"
if [ -z $BUILD_VERSION ]
then
	BUILD_VERSION="X.X.LAB_ONLY"
	PLIXUS_VERSION="0.0.0"
else
	PLIXUS_VERSION=$BUILD_VERSION
fi
echo $BUILD_VERSION > $TARGET_DIR/etc/version

mkdir -p $TARGET_DIR/etc/plixus
echo $PLIXUS_VERSION > $TARGET_DIR/etc/plixus/version.txt

echo "Add /etc/build_date to build"
if [ -z $BUILD_DATE ]
then
	BUILD_DATE=$(date -Isec)
fi
echo $BUILD_DATE > $TARGET_DIR/etc/build_date

echo "Add /etc/revision to build"
REVISION=`git --git-dir .git rev-parse HEAD`
echo $REVISION > $TARGET_DIR/etc/revision
