#!/bin/sh

SYSCTL_CONF_DEF_PATH=/etc/sysctl.conf
SYSCTL_CONF_WORK_PTAH=/tmp/tcp_sysctl.conf

#------------------------------------------------------------------------------
# function: wifi_download_param_opt
#
# $1 opt cpufreq flag(0: not opt cpufreq, 1: opt cpufreq)
#-----------------------------------------------------------------------------
wifi_download_param_opt()
{
    echo performance > /sys/devices/system/cpu/cpufreq/policy3/scaling_governor

    sysctl -p
}

#------------------------------------------------------------------------------
# function: wifi_download_param_recover
#
# $1 opt cpufreq flag(0: not opt cpufreq, 1: opt cpufreq)
#-----------------------------------------------------------------------------
wifi_download_param_recover()
{
    echo walt > /sys/devices/system/cpu/cpufreq/policy3/scaling_governor
    sysctl -p $SYSCTL_CONF_WORK_PTAH
}

###################################### main  body ################################################

case $1 in
0) # opt param
    wifi_download_param_opt $2
    ;;
1) # recover param
    wifi_download_param_recover $2
    ;;
*)
    echo "input opt type error"
    ;;
esac
