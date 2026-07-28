#!/bin/sh

# Distribute the wrapper around all clients
# Paths on any client are to be set up in the wrapper and hold for all clients if the script is distributed.

ID_FILE=/etc/dropbear/id_dropbear_backup
ALLOWED_CMDS=/mnt/OpenWRT_vaults/global_manage/wrapper_for_remote_clients/allowed_commands.sh

# Helper function to read configuration variables (key: value)    
get_config_var() {                                                
    local file="$1"                                               
    local var="$2"                                                
    if [ -f "$file" ]; then                                       
        sed -n "s/^$var:[[:space:]]*//p" "$file" | sed 's/[[:space:]]*$//'
    fi                                                                    
}                                                                         

for i in  /mnt/OpenWRT_vaults/busyback_bank/*/manage/busyback.conf ; do 
    CLIENT=$(get_config_var "$i" "client")             
    CLIENT="${CLIENT:-localhost}"
    PORT=$(get_config_var "$i" "port")   
    PORT="${PORT:-22}"
    USER=$(get_config_var "$i" "user")   
    USER="${USER:-root}"
#    echo ssh -p $PORT -i /etc/dropbear/id_dropbear_backup ${USER}@${CLIENT} exit
#    rsync -e "ssh -i /etc/dropbear/id_dropbear_backup" /mnt/OpenWRT_vaults/global_manage/bin/allowed_commands.sh  root@hawking:.ssh
#    echo rsync -e \"ssh -p $PORT -i /etc/dropbear/id_dropbear_backup\" -ivv /mnt/OpenWRT_vaults/global_manage/wrapper_for_remote_clients/allowed_commands.sh ${USER}@${CLIENT}:.ssh 
    echo rsync -e \"ssh -p $PORT -i ${ID_FILE}\" -ivv ${ALLOWED_CMDS} ${USER}@${CLIENT}:.ssh 
done | sort -u | awk '{ print "calling:>>"$0"<<" ; system($0" </dev/null") }'
#done | sort -u | grep priser | awk '{ print "calling:>>"$0"<<" ; system($0" </dev/null") }'
 

