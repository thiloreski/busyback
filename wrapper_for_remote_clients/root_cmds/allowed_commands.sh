#!/bin/bash
#
# You can have only one forced command in ~/.ssh/authorized_keys. Use this
# wrapper to allow several commands.

MY_PATH=`pwd`/.ssh
BASENAME=`basename $0`
STDOUT_LOG_FILE=${MY_PATH}/${BASENAME%.sh}_`/bin/date +\%Y-\%m-\%d_\%H-\%M-\%S`_stdout.log
echo "deleted by aging" >&2
find ${MY_PATH}/${BASENAME%.sh}*.log -ctime +2 | tee ${MY_PATH}/${BASENAME%.sh}_deleted_`/bin/date +\%Y-\%m-\%d_\%H-\%M-\%S`.log | xargs rm -fv 
echo "deleted by zero size" >&2
rm -vf `find .ssh -size -1` >&2
# skip stdout? "rsync" commands have huge output and will flood FS....
# List here those where not to log stdout
COMMANDS_TO_SKIP_STDOUT=(rsync)

echo =========================== >&2
date >&2
echo -n "I am instructed to run: " >&2
echo ">>${SSH_ORIGINAL_COMMAND}<<" >&2
echo -n "SSH Connection: " >&2
echo ">>${SSH_CONNECTION}<<" >&2
# skip stdout of the comand?
SKIP_STDOUT=0
for i in ${COMMANDS_TO_SKIP_STDOUT[@]}; do
        FOUND_SKIP_CMMAND=`expr "$SSH_ORIGINAL_COMMAND" : $i`
        if (( ${FOUND_SKIP_CMMAND} > 0 )) ; then 
                SKIP_STDOUT=1
        fi
done

#extglob:
#to indicate repetition of chars, pout "*" or "+" before the brackets!
#?(x) or *([x]) means: 0 or 1.
#*(x) or *([x]) means: 0 or more (as x* in Regex).
#+(x) or +([x]) means: 1 or more (as x+ in Regex).
#?(xy) means: 0 or 1 "xy" (as string).
#*(xy) means: 0 or more of "xy" (as string).
#+(xy) means: 1 or more of "xy" (as string).
#?([xy]) means: 1 or zero of x or y. 
#+([xy]) means: 1 or more x or y, matches "xy", "xxyy", "xyxyx", ....
#*([xy]) - got it?
#@(abc|def|ghi) - exact one of abc, def, or ghi

# the rsync command covers a considerable set of different options by the above extglob espressions.
# If something is wrong the calling server gets an error like "protokoll Error- is your sheill clean".

shopt -s extglob
case "$SSH_ORIGINAL_COMMAND" in
        rsync\ --server\ --sender\ -*([vnklLH])ogD?(t)p?(A)?(X)r*(x)e.iL?(s)fxCIvu\ *(--timeout=*([0-9])\ |--ignore-errors\ |--safe-links\ |--numeric-ids\ ).\ \/@(etc|home|other_backup_sources_go_here\/with_subdirs)?(\/) | \
        "rsync --server -vve.LfxCIvu --log-format=%i . .ssh" | \
        "rsync --version"                  | \
        "exit"                             | \
        "cat /etc/hosts"                   | \
        "ls -alt /etc"  )                  
        # "rsync --server -e.LfxCIvu . .ssh" for distributing the allowed_command.sh script
        # "exit" for availability check
        # last entries for testing
        if (( ${SKIP_STDOUT} > 0 )) ; then 
                        $SSH_ORIGINAL_COMMAND 
                        RET_CODE=$?
                else
                        $SSH_ORIGINAL_COMMAND | tee ${STDOUT_LOG_FILE}
                        RET_CODE=$?
                fi
                echo "command executed" >&2
                echo "return code: " $RET_CODE >&2
                echo "output on stdout (this is the output to stderr)" >&2
                ;;
        *)
                echo "Access denied" | tee ${STDOUT_LOG_FILE}
                echo "Not in the list of allowed commands! Access denied" >&2
                echo "command not executed" >&2
                exit 1
                ;;
esac
shopt -u extglob

