#!/bin/sh
echo $PATH >> /dev/kmsg

echo "<3> [test] Init to start_dji_camera3" >> /dev/kmsg

VERSION_FILE="/blackbox/system/ver_info.txt"
PROP_NAME="persist.camera.boot_flag"
GST_CACHE_DIR="/blackbox/camera/gstreamer1.0/.cache/"

VERSION="$(sed -nE 's/.*"Version"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' "$VERSION_FILE" | head -n1)"
CURRENT_PROP="$(getprop "$PROP_NAME" 2>/dev/null)"

echo "<3> [test] firmware version: '$VERSION' gst cache version: '$CURRENT_PROP'" >> /dev/kmsg

if [ -z "$VERSION" ] || [ -z "$CURRENT_PROP" ] || [ "$VERSION" != "$CURRENT_PROP" ]; then
  setprop "$PROP_NAME" "$VERSION"
  if [ -e "$GST_CACHE_DIR" ]; then
    rm -rf "$GST_CACHE_DIR"
    echo "<3> [test]: removed old gst cache." >> /dev/kmsg
  fi
fi

LD_PRELOAD=libdcam_hook.so:libqcom_adapter.so:libdcam_prod_hook.so:libdebuggerd_handler_core.so:libdebuggerd_handler_fallback.so /usr/bin/dji_camera3 -g -u -T

echo "<3> [test]: start_dji_camera3 end. " >> /dev/kmsg
