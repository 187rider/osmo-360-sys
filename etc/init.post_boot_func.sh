#! /bin/sh

# hotplug_cpu 函数
# 这个函数用于热插拔CPU核心。
# 参数：
#   \$1 - 核心ID（core ID）
#   \$2 - 操作类型（0 表示拔核，1 表示插核）
hotplug_cpu()
{
	if [ $(cat /sys/devices/system/cpu/cpu$1/online) -eq $(( !!$2 )) ]; then
		return 0
	fi

	cpu_online=$(( !$2 ))
	times=10
	while [ $cpu_online -eq $(( !$2 )) ] && [ $times -gt 0 ]
	do
		echo $(( !!$2 )) > /sys/devices/system/cpu/cpu$1/online
		usleep 1000
		cpu_online=$(cat /sys/devices/system/cpu/cpu$1/online)
		echo "cpu$1 status: $cpu_online" > /dev/kmsg
		let times=times-1
	done
}
