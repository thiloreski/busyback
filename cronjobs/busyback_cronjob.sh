#!/bin/sh

B=/mnt/OpenWRT_vaults/busyback_bank
find ${B} -maxdepth 2 | grep "/20" | sort > ${B}/f_1
busyback go
find ${B} -maxdepth 2 | grep "/20" | sort > ${B}/f_2
diff ${B}/f_1 ${B}/f_2
ls -l ${B}/4TBO_*/manage/ | grep last_successful_run
#TODO: remove old logs
rm ${B}/f_1 ${B}/f_2 

