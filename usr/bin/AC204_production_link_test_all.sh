#!/bin/bash
log_file=/blackbox/OQ101_production_link_test_all.file

echo "Begin test" > ${log_file}

test_scripts_list=( "/usr/bin/check_sd_card_insert.sh"
	"/usr/bin/detach_pc.sh"
	"/usr/bin/check_sdcard_bus_speed_mode.sh"
	"/usr/bin/rw_test.sh 2 /mnt/media_rw/sd"
	"/usr/bin/check_ufs_speed.sh"
	"/usr/bin/check_ufs_fs_capacity.sh"
	"/usr/bin/rw_test.sh 2 /mnt/media_rw/emulated" )

systemctl stop dji_camera3

final_test_case_number=0
final_failed_case_number=0

begin_time=$(date +%s%N)

for i in "${test_scripts_list[@]}"; do
	test_start_time=$(date +%s%N)
	final_test_case_number=$(expr ${final_test_case_number} + 1)
	eval $i >> ${log_file} 2>/dev/null
	if [ $? -eq 1 ]; then
		final_failed_case_number=$(expr ${final_failed_case_number} + 1)
		echo "case [$i] failed !"
	fi
	echo "time consumed for case [$i] is $(expr $(expr $(date +%s%N) - ${test_start_time}) / 1000) us"
done

echo "time consumed for all case is $(expr $(expr $(date +%s%N) - ${begin_time}) / 1000) us"

echo "total test case number is ${final_test_case_number}, fail case number is ${final_failed_case_number}"

echo "End test" >> ${log_file} 2>/dev/null

systemctl restart dji_camera3

if [ ${final_failed_case_number} -eq 0 ]; then
	echo ":     | |                  "
	echo ":   __| | ___  _ __   ___  "
	echo ":  / _  |/ _ \|  _ \ / _ | "
	echo ": | (_| | (_) | | | |  __/"
	echo ":  \__,_|\___/|_| |_|\___|"
	echo "Test success !!"
	exit 0
else
	echo "    --------        --           ----           ||"
	echo "    |              /  \           ||            ||"
	echo "    |             /    \          ||            ||"
	echo "    |             /    \          ||            ||"
	echo "    |-------     /------\         ||            ||"
	echo "    |            /      \         ||            ||"
	echo "    |           /        \        ||            ||"
	echo "    |          /          \      ----           ///////////"
	echo "Test failed !!"
	exit 1
fi