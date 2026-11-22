#!/bin/sh

directory="/blackbox/system/utop"
file_count=$(ls -1 $directory | wc -l)
if [ $file_count -gt 8 ]; then
    files_to_delete=$(ls -1t $directory | tail -n +9)
    for file in $files_to_delete; do
        rm "$directory/$file"
        echo "UTOP Deleted file: $directory/$file" > /dev/kmsg
    done
else
    echo "UTOP No files to delete. File count is $file_count." > /dev/kmsg
fi

echo "starting dji_utop" > /dev/kmsg
dji_utop -d 500 -c /system/etc/top.cfg -o /blackbox/system/utop/utop_`date '+%Y%m%d%H%M%S'`.log
