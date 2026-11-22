#! /bin/sh
systemctl stop dji_camera3
sleep 2
systemctl stop qmmf-server
sleep 2

DSP_LIBRARY_PATH=/usr/lib/rfsa/dsp LD_LIBRARY_PATH=/usr/lib64/ dji_ppt -a -f -L /system/etc/ppt_cases.conf -b /mnt/media_rw/emulated/pp_test_dataset -e

systemctl start qmmf-server
sleep 2
systemctl start dji_camera3
sleep 2
