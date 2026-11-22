#!/bin/sh

# do not set / (root_file) to rw, that make diff-upgrade failed 
# mount -o rw,remount /

logcat -v threadtime -f /blackbox/gui/log/gui.log -r16384 -n3 DUSS4A:I *:S
