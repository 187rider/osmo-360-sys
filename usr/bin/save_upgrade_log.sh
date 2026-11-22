#!/bin/sh

# do not set / (root_file) to rw, that make diff-upgrade failed 
# mount -o rw,remount /

logcat -v threadtime -f /blackbox/system/upgrade.log -r8192 -n4 DUSS63:I FTP:V *:S
