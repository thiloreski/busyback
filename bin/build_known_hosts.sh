#!/bin/sh

# Busyback need an entry in the known hosts file to connect to clients.
# On first connction , i.e. if ther is no entry for the client the knowin_hosts file, there will be a confirmation prompt
# if this happens in the cron job, the jpob hangs.
# This little helper juns through all busyback conf files and does a ssh connection whith single command "exoit" to each found client
# Answer yes (y) to the prompt, and the client and its host key is inserted into the knpown hosts file (login is not needed)
# Of coourse only works for reachable clients and also be aware of the forced command wrapper on the cliient

# Helper function to read configuration variables (key: value)    
get_config_var() {                                                
    local file="$1"                                               
    local var="$2"                                                
    if [ -f "$file" ]; then                                       
        sed -n "s/^$var:[[:space:]]*//p" "$file" | sed 's/[[:space:]]*$//'
    fi                                                                    
}                                                                         

TMPFILE=/tmp/$$

for i in  /mnt/OpenWRT_vaults/busyback_bank/*/manage/busyback.conf ; do 
    CLIENT=$(get_config_var "$i" "client")             
    CLIENT="${CLIENT:-localhost}"
    PORT=$(get_config_var "$i" "port")   
    PORT="${PORT:-22}"
    USER=$(get_config_var "$i" "user")   
    USER="${USER:-root}"
    echo ssh -p $PORT -i /etc/dropbear/id_dropbear_backup ${USER}@${CLIENT} exit
done | sort -u | awk '{ print "calling:>>"$0"<<" ; system($0" </dev/null") }'
