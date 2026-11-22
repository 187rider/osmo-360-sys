#!/bin/sh

# do not set / (root_file) to rw, that make diff-upgrade failed 
# mount -o rw,remount /

logcat -v threadtime -f /blackbox/system/system.log -r65536 -n9 DUSS5A*:I weston:I storage-service:I DUSS4A*:I DUSS4D*:I DUSS26:I DUSS5C:I DUSS8C:I DUSS7F:I DUSS85*:I DjiPlayer*:I OmxPlayer*:I OMX*:W SysMode:I *:E hostapd wpa_supplicant lbluez_app bluetoothd
