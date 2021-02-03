#!/bin/sh
# post-image.sh for televic regular/upgrade build
# 2016, Theo Debrouwere <t.debrouwere@televic.com>
# 2019, Arno Messiaen <a.messiaen@televic.com>

echo "dir: $BINARIES_DIR/"

if [ -z $BUILD_VERSION ]
then
	BUILD_VERSION="X.X.LAB_ONLY"
fi

echo "Copy upgrade.sh"
cp board/televic/confidea_g4_wdu/upgrade.sh $BINARIES_DIR/upgrade.sh
chmod a+x $BINARIES_DIR/upgrade.sh

echo "Calculate md5sums: "
MD5SUM_ROOTFS=$(md5sum $BINARIES_DIR/rootfs.tar.xz | sed 's/\([^ ]*\)[ ].*/\1/')

echo "Rootfs: $MD5SUM_ROOTFS"

echo "Generate sys_contents.txt file - describing rootfs"
echo "{
    \"author\": \"Televic Conference NV\",
    \"checksum\": \"$MD5SUM_ROOTFS\",
    \"description\": \"Software release\",
    \"files\": [
        {
            \"md5\": \"$MD5SUM_ROOTFS\",
            \"name\": \"rootfs.tar.xz\"
        }
    ],
    \"partition\": \"rootfs.tar.xz\",
    \"rootsize\": 0,
    \"upgscript\": \"upgrade.sh\",
    \"version\": \"$BUILD_VERSION\"
}" > $BINARIES_DIR/sys_contents.txt

echo "Create cg4-wdu-files.tar.gz"
tar czf $BINARIES_DIR/cg4-wdu-files.tar.gz --owner=0 --group=0 -C $BINARIES_DIR rootfs.tar.xz sys_contents.txt upgrade.sh

echo "Generate inner contents.txt file - describing cg4-wdu-files.tar.gz"
echo "{
    \"description\": \"uniCOS Customer Release Package\",
    \"author\": \"Televic Conference NV\",
    \"version\": \"$BUILD_VERSION\",
    \"files\": [
        {
            \"platform\": \"Unicos\",
            \"platform-version\": \"1.0\",
            \"target\": \"0xF640\",
            \"offset\": \"0x00\",
            \"name\": \"cg4-wdu-files.tar.gz\",
            \"version\": \"$BUILD_VERSION\",
            \"force\": true
        }
    ]
}" > $BINARIES_DIR/contents.txt

echo "Create confidea-g4-wdu-upgrade.tuf"
tar czf $BINARIES_DIR/confidea-g4-wdu-upgrade.tuf --owner=0 --group=0 -C $BINARIES_DIR cg4-wdu-files.tar.gz contents.txt
mv $BINARIES_DIR/contents.txt $BINARIES_DIR/contents_inner.txt

echo "Generate outer contents.txt file - describing confidea-g4-wdu-upgrade.tuf"
echo "{
    \"description\": \"uniCOS Customer Release Package\",
    \"author\": \"Televic Conference NV\",
    \"version\": \"$BUILD_VERSION\",
    \"files\": [
        {
            \"platform\": \"Unicos\",
            \"platform-version\": \"1.0\",
            \"target\": \"0xF6B0\",
            \"devices\": [\"0x0610\"],
            \"offset\": \"0x00\",
            \"name\": \"confidea-g4-wdu-upgrade.tuf\",
            \"version\": \"$BUILD_VERSION\",
            \"force\": true
        }
    ]
}" > $BINARIES_DIR/contents.txt

echo "Create confidea_g4_sw_wdu_$BUILD_VERSION.tuf"
tar czf $BINARIES_DIR/confidea_g4_sw_wdu_$BUILD_VERSION.tuf --owner=0 --group=0 -C $BINARIES_DIR confidea-g4-wdu-upgrade.tuf contents.txt
rm $BINARIES_DIR/confidea-g4-wdu-upgrade.tuf
