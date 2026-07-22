#!/bin/sh

B=/mnt/OpenWRT_vaults/busyback_bank
find ${B} -maxdepth 2 | grep "/20" | sort > ${B}/f_1
trap 'rm -rf "${B}/f_1"' EXIT INT TERM HUP
busyback go
find ${B} -maxdepth 2 | grep "/20" | sort > ${B}/f_2
diff ${B}/f_1 ${B}/f_2
trap 'rm -rf "${B}/f_2"' EXIT INT TERM HUP
ls -l ${B}/4TBO_*/manage/ | grep last_successful_run

#rm ${B}/f_1 ${B}/f_2 

