#!/bin/sh 
GLO_MAN=/mnt/OpenWRT_vaults/global_manage
for i in /mnt/OpenWRT_vaults/busyback_bank/4TBO_* ; do 
   SOURCE=${i}/manage/busyback.conf
   TARGET=${GLO_MAN}/config/busyback.vault.configs/$(basename ${i})_busyback.config
   echo "rsync -avvi ${SOURCE} ${TARGET}"
   rsync -avvi ${SOURCE} ${TARGET}
done
crontab -l > /var/tmp/roots_crontab.ctrb
if [ -n "$(diff /var/tmp/roots_crontab.ctrb ${GLO_MAN}/config/roots_crontab.crtb)" ]  ; then 
   if crontab -l > ${GLO_MAN}/config/roots_crontab.crtb ; then
      echo crontab saved successful
   fi
fi

echo "copying to ${GLO_MAN}:"
rsync -avvi /usr/bin/crypto-manage /usr/bin/busyback* ${GLO_MAN}/bin
rsync -avvi /etc/config/cryptsetup /etc/config/fstab /etc/busyback/master.conf ${GLO_MAN}/config

find ${GLO_MAN}/logs/ 
echo "delete old logs"
OLD_LOGS=$(find ${GLO_MAN}/logs/ -mtime +2)
[ -n "$OLD_LOGS" ] && rm -v $OLD_LOGS || echo "no old logs found"
