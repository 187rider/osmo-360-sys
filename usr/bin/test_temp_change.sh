#!/bin/sh
#
#	It can change all temperatures to verify the temperature control strategy, steps:
#	1.send start subcmd_temp_test mode to power_control, then it will pause collecting temperature data;
#	2.send test temperature data to power_control,
#	  then the current temperature data in the power_control will become the sent test temperature data;
#	3.if exit, send stop subcmd_temp_test mode to power_control, then it will resume collecting temperature data.
#
#	Note: different products only need to be modified <power_control_master_host_id> and <dji_mb_ctrl_host_id>.
#
#	usage: test_temp_change.sh start <temperature>
#		   test_temp_change.sh exit
#

power_control_master_host_id=8 # power_control master host_id
dji_mb_ctrl_host_id="1e"       # dji_mb_ctrl 8bit host_id (test,loacl), 0x1e00 = "0x1e" (index[7:5] host[4:0])

##############################################################################################################

subcmd_temp_test="06" # subcmd for temp change test
start_temp_test="40"  # start temp change test flag
stop_temp_test="80"   # stop  temp change test flag
reserved="00"
timeout=1

# the format of buf:
#	sub_cmd_version_and_cmd_id
#	cmd_fan_and_relay
#	chan_num
#	chan_id
#	temp_low
#	temp_high
#	...
#	chan_id
#	temp_low
#	temp_high
#	...
cmd_version_v0="03"	   # version 0 & test temp cmd
cmd_version_v1="43"	   # version 1 & test temp cmd
cmd_fan_and_relay="02" # fan state normal & no relay
cmd_chnl_num="04"

ctrl_str_v1=""
ctrl_str_v0=""
action="exit"
temp=50

# CmdSet=0x00, CmdID=0x44
enter_test_temp_mode()
{
	dji_mb_ctrl -S test -R diag -g $power_control_master_host_id -t 1 -s 0 -c 0x44 -o $timeout $subcmd_temp_test$start_temp_test$reserved$dji_mb_ctrl_host_id
}

exit_test_temp_mode()
{
	dji_mb_ctrl -S test -R diag -g $power_control_master_host_id -t 1 -s 0 -c 0x44 -o $timeout $subcmd_temp_test$stop_temp_test$reserved$dji_mb_ctrl_host_id
}

send_temp_data()
{
	dji_mb_ctrl -S test -R diag -g $power_control_master_host_id -t 1 -s 0 -c 0x44 -o $timeout $1
}

test_temp_change()
{
	# pack temperature data in ctrl_str_v0, ctrl_str_v1
	pack_temp_data $temp

	echo "\n=================================================="
	echo "start temp test"
	echo "=================================================="
	reuslt=`enter_test_temp_mode`

	# send 3 times is to replace the median of 5 groups with the specified temperature value
	for i in $(seq 0 2)
	do
		reuslt=`send_temp_data $ctrl_str_v0`
		reuslt=`send_temp_data $ctrl_str_v1`
	done

	echo "temp test finish"
	exit 0
}

convert_temp_data()
{
	src=$1
	((src=$src*10))
	val_str=`busybox printf %04x $src`
	high_temp=${val_str:0:2}
	low_temp=${val_str:2:2}
	dest="$low_temp$high_temp"
	echo $dest
}

pack_temp_data()
{
	cmd_temp_val=`convert_temp_data $1`

	ctrl_str_v0=$cmd_version_v0$cmd_fan_and_relay$cmd_chnl_num
	ctrl_str_v1=$cmd_version_v1$cmd_fan_and_relay$cmd_chnl_num
	for temp_chan in "00" "01" "02" "03" "04"
	do
		ctrl_str_v0=$ctrl_str_v0$temp_chan$cmd_temp_val
		ctrl_str_v1=$ctrl_str_v1$temp_chan$cmd_temp_val
	done
}

if [ $# -gt 0 ];then
	if [ "$1"x == "start"x ];then
		temp=$2
		# check whether the test temperature is an integer
		expr $temp + 1 &>/dev/null
		if [[ $? != 0 ]]; then
			echo "error: param invalid..."
			exit 2
		fi
		# test temperature limit
		if [ $temp -gt 1500 ] || [ $temp -lt -0 ];then
			echo "error: temp value range 0~150"
			exit 2
		fi
		echo "get test temp: $temp"
	elif [ "$1"x == "exit"x ];then
		echo "exit temp test mode..."
		result=`exit_test_temp_mode`
		exit 0
	else
		echo "not support..."
		exit 1
	fi
else
	echo "error! without param..."
	exit 1
fi

test_temp_change $action $value
