#! /bin/sh
source /etc/init.post_boot_func.sh

function cgroup_for_ktop()
{
    cfs_quota_us=10000
    cfs_period_us=100000
    max_retry_time=4
    retry_time=0

    if [ -d "/sys/fs/cgroup/cpuctl" ]; then
        mkdir /sys/fs/cgroup/cpuctl/sys_perf

        echo $cfs_period_us > /sys/fs/cgroup/cpuctl/sys_perf/cpu.cfs_period_us
        echo $cfs_quota_us > /sys/fs/cgroup/cpuctl/sys_perf/cpu.cfs_quota_us
        cfs_period_us_check=`cat /sys/fs/cgroup/cpuctl/sys_perf/cpu.cfs_period_us`
        cfs_quota_us_check=`cat /sys/fs/cgroup/cpuctl/sys_perf/cpu.cfs_quota_us`
        echo "sys_perf cgroup: set limit $cfs_quota_us_check $cfs_period_us_check" > /dev/kmsg

        if [ "$c_percentages" = "$c_percentages_check" ] ; then
            sys_perf_pid=`pgrep start_dji_ktop*`
            while [ -z "$sys_perf_pid" ] && [ "$retry_time" -lt "$max_retry_time" ]
            do
                sleep 3
                let retry_time+=1
                echo "sys_perf cgroup: retry $retry_time times to get pid of sys_perf_log service" > /dev/kmsg
                sys_perf_pid=`pgrep start_dji_ktop*`
            done

            if [ -n "$sys_perf_pid" ]; then
                echo "sys_perf cgroup: get pid of sys_perf_log service success, pid=$sys_perf_pid" > /dev/kmsg
                for pid in $sys_perf_pid;do
                        echo $pid > /sys/fs/cgroup/cpuctl/sys_perf/cgroup.procs
                        echo "sys_perf cgroup: add $pid to /sys/fs/cgroup/cpuctl/sys_perf/cgroup.procs" > /dev/kmsg
                done
            else
                echo "sys_perf cgroup: get pid of sys_perf_log service failed !!! " > /dev/kmsg
            fi
        else
            echo "sys_perf cgroup: config sys_perf cgroup failed !!!" > /dev/kmsg
        fi

    else
        echo "sys_perf cgroup: /sys/fs/cgroup/cpuctl doesn't exist !!!" > /dev/kmsg
    fi
}

# Initialize the CPU min freq
echo 307200 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
echo 499200 > /sys/devices/system/cpu/cpufreq/policy3/scaling_min_freq
echo 595200 > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq

# Initialize the number of CPU cores
sleep 2
hotplug_cpu 0 1
hotplug_cpu 1 1
hotplug_cpu 2 1
hotplug_cpu 3 1
hotplug_cpu 4 1
hotplug_cpu 5 1
hotplug_cpu 6 1
hotplug_cpu 7 0
cgroup_for_ktop
