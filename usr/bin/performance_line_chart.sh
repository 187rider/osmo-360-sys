#!/bin/sh
product_name="OQ101"
bootloader_time="0.0"
linux_kernel_time="0.0"
dji_camera3_time="0.0"
dji_gui_time="0.0"
camera_service_start_time="0.0"
liveview_ready_time="0.0"
gui_osd_shown_time="0.0"

# do not set / (root_file) to rw, that make diff-upgrade failed 
# mount -o rw,remount /

echo "save dmesg log"
dmesg > /blackbox/system/dmesg.log
echo $(cat /blackbox/system/dmesg.log | grep 'KPI: Bootloader start count')
echo $(cat /blackbox/system/dmesg.log | grep 'KPI: Bootloader end count')
echo $(cat /blackbox/system/dmesg.log | grep 'KPI: Bootloader load kernel count')
echo $(cat /blackbox/system/dmesg.log | grep 'KPI: Kernel MPM timestamp')
echo $(cat /blackbox/system/dmesg.log | grep 'KPI: Kernel MPM Clock frequency')
echo -e "\n"
linux_time_stamp=$(cat /blackbox/system/dmesg.log | grep 'KPI: Kernel MPM timestamp =' | grep -o '\[[^]]*\]' | sed 's/\[\s*//;s/\s*\]//' | cut -d 'T' -f1)
echo "linux_time_stamp:"
echo -e "$linux_time_stamp\n"
bootloader_clk_count=$(cat /blackbox/system/dmesg.log | grep 'KPI: Kernel MPM timestamp =' | awk -F "=" '{print $2}' | awk '{printf("%d", $1)}')
echo "bootloader_clk_count:"
echo -e "$bootloader_clk_count\n"
kernel_mpm_clk_freq=$(cat /blackbox/system/dmesg.log | grep 'KPI: Kernel MPM Clock frequency =' | awk -F "=" '{print $2}' | awk '{printf("%d", $1)}')
echo "kernel_mpm_clk_freq:"
echo -e "$kernel_mpm_clk_freq\n"
bootloader_start_time=$(echo $bootloader_clk_count $kernel_mpm_clk_freq $linux_time_stamp | awk '{printf("%f", $1/$2-$3)}')
echo "bootloader_start_time:"
echo -e "$bootloader_start_time\n"
bootloader_time="$bootloader_start_time"

linux_kernel_start_time_relative=$(cat /blackbox/system/dmesg.log | grep 'Warning: unable to open an initial console' | grep -o '\[[^]]*\]' | sed 's/\[\s*//;s/\s*\]//' | cut -d 'T' -f1)
linux_kernel_start_time=$(echo $bootloader_start_time $linux_kernel_start_time_relative | awk '{printf("%f", $1+$2)}')
echo "linux_kernel_start_time:"
echo -e "$linux_kernel_start_time\n"
linux_kernel_time="$linux_kernel_start_time"

camera_service_start_time_relative=$(cat /blackbox/system/dmesg.log | grep 'CameraService DJI Camera Service for Seal is starting...' | grep -o '\[[^]]*\]' | sed 's/\[\s*//;s/\s*\]//' | cut -d 'T' -f1)
camera_service_start_time=$(echo $bootloader_start_time $camera_service_start_time_relative | awk '{printf("%f", $1+$2)}')
echo "camera_service_start_time:"
echo -e "$camera_service_start_time\n"
dji_camera3_time="$camera_service_start_time"

gui_service_start_time_relative=$(cat /blackbox/system/dmesg.log | grep 'DJI Gui Service is starting...' | grep -o '\[[^]]*\]' | sed 's/\[\s*//;s/\s*\]//' | cut -d 'T' -f1)
gui_service_start_time=$(echo $bootloader_start_time $gui_service_start_time_relative | awk '{printf("%f", $1+$2)}')
echo "gui_service_start_time:"
echo -e "$gui_service_start_time\n"
dji_gui_time="$gui_service_start_time"

json_template="{\"version\": 1, \"data\": [{\"type_name\": \"\\u9636\\u6bb5\\u8017\\u65f6\", \"type_display_name\": \"\\u9636\\u6bb5\\u8017\\u65f6\", \"unit\": \"s\", \"values\": [{\"display_name\": \"EMMC \\u521d\\u59cb\\u5316\", \"name\": \"EMMC \\u521d\\u59cb\\u5316\", \"description\": \"Smaller is better\", \"value\": 0}, {\"display_name\": \"DDR \\u521d\\u59cb\\u5316\", \"name\": \"DDR \\u521d\\u59cb\\u5316\", \"description\": \"Smaller is better\", \"value\": 0}]}, {\"type_name\": \"$product_name\\uff08\\u8be6\\u7ec6\\u542f\\u52a8\\u65f6\\u95f4\\u56fe\\uff09\", \"type_display_name\": \"$product_name\\uff08\\u8be6\\u7ec6\\u542f\\u52a8\\u65f6\\u95f4\\u56fe\\uff09\", \"unit\": \"s\", \"values\": [{\"display_name\": \"Bootrom \\u5b8c\\u6210\\u542f\\u52a8\", \"name\": \"Bootrom \\u5b8c\\u6210\\u542f\\u52a8\", \"description\": \"Smaller is better\", \"value\": 0.0}, {\"display_name\": \"\\u79bb\\u5f00 Bootloader\", \"name\": \"\\u79bb\\u5f00 Bootloader\", \"description\": \"Smaller is better\", \"value\": $bootloader_time}, {\"display_name\": \"Linux \\u521d\\u59cb\\u5316\\u5b8c\\u6210\", \"name\": \"Linux \\u521d\\u59cb\\u5316\\u5b8c\\u6210\", \"description\": \"Smaller is better\", \"value\": $linux_kernel_time}, {\"display_name\": \"\\u5f00\\u59cb\\u542f\\u52a8dji_camera3\", \"name\": \"\\u5f00\\u59cb\\u542f\\u52a8dji_camera3\", \"description\": \"Smaller is better\", \"value\": $dji_camera3_time}, {\"display_name\": \"camera service main \\u51fd\\u6570\\u5f00\\u59cb\\u6267\\u884c\", \"name\": \"camera service main \\u51fd\\u6570\\u5f00\\u59cb\\u6267\\u884c\", \"description\": \"Smaller is better\", \"value\": $camera_service_start_time}, {\"display_name\": \"Gui Service is starting\", \"name\": \"Gui Service is starting\", \"description\": \"Smaller is better\", \"value\": $dji_gui_time}, {\"display_name\": \"\\u76f8\\u673aliveview ready for gui\", \"name\": \"\\u76f8\\u673aliveview ready for gui\", \"description\": \"Smaller is better\", \"value\": $liveview_ready_time}, {\"display_name\": \"Gui App osd is shown\", \"name\": \"Gui App osd is shown\", \"description\": \"Smaller is better\", \"value\": $gui_osd_shown_time}]}]}"
echo $json_template > /blackbox/camera/log/performance_line_chart.json

