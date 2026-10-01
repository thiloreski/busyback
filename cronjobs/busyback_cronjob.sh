#!/bin/sh
B=/mnt/OpenWRT_vaults/busyback_bank
trap "echo 'delete f_1/2' ;  rm -rf ${B}/f_2 ${B}/f_1" EXIT INT TERM HUP
find ${B} -maxdepth 2 | grep "/20" | sort > ${B}/f_1
busyback go
find ${B} -maxdepth 2 | grep "/20" | sort > ${B}/f_2
echo 'deleted:"
diff ${B}/f_1 ${B}/f_2 | grep "^<"
echo 'created:"
diff ${B}/f_1 ${B}/f_2 | grep "^>"
ls -l ${B}/4TBO_*/manage/ | grep last_successful_run
