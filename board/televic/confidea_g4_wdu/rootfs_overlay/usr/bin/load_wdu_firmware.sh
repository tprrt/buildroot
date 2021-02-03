#!/bin/sh

# check if sdma firmware loading node is present
if [ ! -f /sys/class/firmware/imx!sdma!sdma-imx7d.bin/loading ]
then
	echo "No loading node available - skipping."
	return 1
fi

# check content
BOARD=$(cat /etc/board)

if [ "$BOARD" != "confidea_g4_wdu" ]
then
	echo "Using wrong firmware loading script."
	return 1
fi

echo 1 > /sys/class/firmware/imx!sdma!sdma-imx7d.bin/loading
cat /lib/firmware/imx/sdma/sdma-imx7d.bin > /sys/class/firmware/imx!sdma!sdma-imx7d.bin/data
echo 0 > /sys/class/firmware/imx!sdma!sdma-imx7d.bin/loading

exit 0
