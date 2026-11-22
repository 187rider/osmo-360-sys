#!/bin/sh

# echo print param test $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13} ${14} ${15} ${16} ${17}

###########platform:eagle2, chip type: broadcom43752, macro define###############
BCM_KO_PATH=/system/lib/modules/bcmdhd.ko
BCM_FW_PATH=/vendor/firmware/fw_bcmdhd.bin
BCM_FW_MFG_PATH=/vendor/firmware/fw_bcmdhd_factory.bin
BCM_NVRAM_PATH=/vendor/firmware/nvram.txt
BCM_NVRAM_LOW_POWER_PATH=/vendor/firmware/nvram_lower_power_3db.txt
BCM_NVRAM_CE_PATH=/vendor/firmware/nvram_ce.txt
BCM_CLM_BLOB_PATH=/vendor/firmware/bcmdhd_clm.blob

BCM_FW43456_MFG_PATH=/vendor/firmware/43456-sdio-mfg.bin
BCM_CLM_BLOB43456_PATH=/vendor/firmware/clm_bcm43456c5_ag.blob

BCM_FW43752_MFG_PATH=/vendor/firmware/fw_bcmdhd_factory.bin
BCM_CLM_BLOB43752_PATH=/vendor/firmware/clm_bcm43752a2_pcie_ag.blob

BCM_MAC_ADDR_FILE=/data/misc/wifi/softmac.bin
BCM_DEF_CFG_PATH=/system/etc/hostapd.conf
BCM_WORK_CFG_PATH=/data/misc/wifi/hostapd.conf

BCM_BT_APP_DEF_PATH=/system/bin/simple_app
BCM_BT_APP_WORK_PATH=/data/misc/bluetooth/simple_app

SYSCTL_CONF_DEF_PATH=/etc/sysctl.conf
SYSCTL_CONF_WORK_PTAH=/tmp/tcp_sysctl.conf

WPA_SUPPLICANT_DEF_CFG_PATH=/system/etc/wpa_supplicant.conf
WPA_SUPPLICANT_WORK_CFG_PATH=/data/misc/wifi/wpa_supplicant.conf

###########platform:eagle2, chip type: cypress43455, macro define###############
#use broadcom43752`s macro define
CYP_NVRAM_PATH=$BCM_NVRAM_PATH
CYP_NVRAM_CE_PATH=$BCM_NVRAM_CE_PATH
CYP_NVRAM_WORK_PATH=/tmp/nvram.txt

CYP_BT_APP_DEF_PATH=/usr/bin/simple_app
CYP_BT_APP_WORK_PATH=/tmp/simple_app

###########platform:e3t, chip type: uwe2652, macro define###############
UWE_WIFI_DEF_HOSTAPD_PATH=/system/etc/hostapd.conf
UWE_WIFI_CFG_HOSTAPD_PATH=/data/misc/wifi/hostapd.conf
UWE_WIFI_CFG_UDHCPD_FILE=/etc/udhcpd_wlan0.conf

###########platform:e1e, chip type: qca6174a, macro define###############
QCA_WIFI_CFG_HOSTAPD_PATH=/cali/wifi/hostapd.conf


########################################platform:common,function define#########################
read_current_tcp_param()
{
	file_max=$(cat /proc/sys/fs/file-max)
	busybox sed -i "s/fs.file-max = .*/fs.file-max = ${file_max}/" $SYSCTL_CONF_WORK_PTAH

	netdev_max_backlog=$(cat /proc/sys/net/core/netdev_max_backlog)
	busybox sed -i "s/net.core.netdev_max_backlog = .*/net.core.netdev_max_backlog = ${netdev_max_backlog}/" $SYSCTL_CONF_WORK_PTAH

	optmem_max=$(cat /proc/sys/net/core/optmem_max)
	busybox sed -i "s/net.core.optmem_max = .*/net.core.optmem_max = ${optmem_max}/" $SYSCTL_CONF_WORK_PTAH

	rmem_default=$(cat /proc/sys/net/core/rmem_default)
	busybox sed -i "s/net.core.rmem_default = .*/net.core.rmem_default = ${rmem_default}/" $SYSCTL_CONF_WORK_PTAH

	rmem_max=$(cat /proc/sys/net/core/rmem_max)
	busybox sed -i "s/net.core.rmem_max = .*/net.core.rmem_max = ${rmem_max}/" $SYSCTL_CONF_WORK_PTAH

	wmem_default=$(cat /proc/sys/net/core/wmem_default)
	busybox sed -i "s/net.core.wmem_default = .*/net.core.wmem_default = ${wmem_default}/" $SYSCTL_CONF_WORK_PTAH

	wmem_max=$(cat /proc/sys/net/core/wmem_max)
	busybox sed -i "s/net.core.wmem_max = .*/net.core.wmem_max = ${wmem_max}/" $SYSCTL_CONF_WORK_PTAH

	tcp_mem=$(cat /proc/sys/net/ipv4/tcp_mem)
	busybox sed -i "s/net.ipv4.tcp_mem = .*/net.ipv4.tcp_mem = ${tcp_mem}/" $SYSCTL_CONF_WORK_PTAH

	tcp_rmem=$(cat /proc/sys/net/ipv4/tcp_rmem)
	busybox sed -i "s/net.ipv4.tcp_rmem = .*/net.ipv4.tcp_rmem = ${tcp_rmem}/" $SYSCTL_CONF_WORK_PTAH

	tcp_wmem=$(cat /proc/sys/net/ipv4/tcp_wmem)
	busybox sed -i "s/net.ipv4.tcp_wmem = .*/net.ipv4.tcp_wmem = ${tcp_wmem}/" $SYSCTL_CONF_WORK_PTAH

	tcp_limit_output_bytes=$(cat /proc/sys/net/ipv4/tcp_limit_output_bytes)
	busybox sed -i "s/net.ipv4.tcp_limit_output_bytes = .*/net.ipv4.tcp_limit_output_bytes = ${tcp_limit_output_bytes}/" $SYSCTL_CONF_WORK_PTAH
}

#------------------------------------------------------------------------------
# function: wifi_download_param_opt
#
# $1 opt cpufreq flag(0: not opt cpufreq, 1: opt cpufreq)
#-----------------------------------------------------------------------------
wifi_download_param_opt()
{
    if [ ! -f $SYSCTL_CONF_WORK_PTAH ];then
        cp $SYSCTL_CONF_DEF_PATH $SYSCTL_CONF_WORK_PTAH
    fi

    read_current_tcp_param

    if [ $1 -eq 1 ];then
        busybox taskset -p 78 $(pidof dji_http_server)
    fi

    sysctl -p
}

start_udhcpd()
{
    lines=$(busybox pgrep busybox | wc -l)
    i=1
    while (( i<=$lines))
    do
        pid=$(busybox pgrep busybox | busybox awk 'NR=="'$i'" {print $1}')
        udhcpd_name=$(cat /proc/$pid/cmdline | busybox awk 'NR ==2 {print $1}')

        if [[ "$udhcpd_name" = "udhcpd" ]];then
            udhcpd_conf_file=$(cat /proc/$pid/cmdline | busybox awk 'NR ==3 {print $1}')
            if [[ "$udhcpd_conf_file" = "/etc/udhcpd_wlan0.conf" ]];then
                return
            fi
        fi

        let i++
    done

    busybox udhcpd /etc/udhcpd_wlan0.conf

    echo "start udhcpd finish"
}

kill_udhcpd()
{
    lines=$(busybox pgrep busybox | wc -l)
    i=1
    while (( i<=$lines))
    do
        pid=$(busybox pgrep busybox | busybox awk 'NR=="'$i'" {print $1}')
        udhcpd_name=$(cat /proc/$pid/cmdline | busybox awk 'NR ==2 {print $1}')

        if [[ "$udhcpd_name" = "udhcpd" ]];then
            udhcpd_conf_file=$(cat /proc/$pid/cmdline | busybox awk 'NR ==3 {print $1}')
            if [[ "$udhcpd_conf_file" = "/etc/udhcpd_wlan0.conf" ]];then
                busybox kill $pid
            fi
        fi

        let i++
    done

    echo "kill udhcpd finish"
}

start_dnsmasq()
{
    lines=$(busybox pgrep dnsmasq | wc -l)
    i=1
    while (( i<=$lines))
    do
        pid=$(busybox pgrep dnsmasq | busybox awk 'NR=="'$i'" {print $1}')
        process_name=$(cat /proc/$pid/cmdline | busybox awk -F ' ' 'NR==1 {print $1}')

        if [[ "$process_name" = "dnsmasq" ]];then
            return
        fi

        let i++
    done

    if [ ! -d /data/misc/dhcp/ ];then
        mkdir /data/misc/dhcp/
    fi

    if [ ! -d /tmp/run/ ];then
        mkdir /tmp/run/
    fi

    dnsmasq --nodns --port=0 --no-ping --dhcp-authoritative -R -n --pid-file=/tmp/run/dnsmasq.pid --dhcp-range=192.168.2.2,192.168.2.200,infinite
    echo "start dnsmasq finish"
}

kill_dnsmasq()
{
    lines=$(busybox pgrep dnsmasq | wc -l)
    i=1
    while (( i<=$lines))
    do
        pid=$(busybox pgrep dnsmasq | busybox awk 'NR=="'$i'" {print $1}')
        process_name=$(cat /proc/$pid/cmdline | busybox awk -F ' ' 'NR==1 {print $1}')

        if [[ "$process_name" = "dnsmasq" ]];then
            busybox kill $pid
            break
        fi

        let i++
    done

    echo "kill dnsmasq finish"
}

device_stop_hostapd()
{
    busybox killall hostapd
    ifconfig wlan0 default
    ifconfig wlan0 down

    echo "stop hostapd finish"
}

#------------------------------------------------------------------------------
# function: device_start_hostapd
#
# $1 channel, $2 ssid, $3 passwd, $4 alpha2(country code)
#-----------------------------------------------------------------------------

device_start_hostapd()
{
    cp $BCM_DEF_CFG_PATH $BCM_WORK_CFG_PATH
    chmod 777 $BCM_WORK_CFG_PATH
    if [ ! -f "$BCM_WORK_CFG_PATH" ];then
        echo work config file--hostapd.conf not exist!
    fi

    busybox sed -i 's/^ctrl_interface=.*/ctrl_interface=\/data\/misc\/wifi\/sockets/' $BCM_WORK_CFG_PATH

    if [ -n "$2" ];then
        busybox sed -i "s/^ssid=.*/ssid=$2/" $BCM_WORK_CFG_PATH
    fi

    if [ -n "$3" ];then
        busybox sed -i "s/^wpa_passphrase=.*/wpa_passphrase=$3/" $BCM_WORK_CFG_PATH
    fi

    if [ $1 -lt 15 ];then
        busybox sed -i 's/^hw_mode=.*/hw_mode=g/' $BCM_WORK_CFG_PATH
    else
        busybox sed -i 's/^hw_mode=.*/hw_mode=a/' $BCM_WORK_CFG_PATH
    fi

    busybox sed -i "s/^channel=.*/channel=$1/" $BCM_WORK_CFG_PATH

    if [ -n "$4" ];then
        busybox sed -i "s/^country_code=.*/country_code=$4/" $BCM_WORK_CFG_PATH
    fi

    hostapd -B $BCM_WORK_CFG_PATH

    echo "start hostapd finish"
}

#--------------------------------------------------------------------------------------
# function: bcm_device_stop_wpa_supplicant
#
# $1 ap
#-------------------------------------------------------------------------------------
device_stop_wpa_supplicant()
{
    busybox kill -9 `ps -ef | grep 'udhcpc' | busybox awk '{print $2}' | busybox sed -n 1p`

    busybox killall wpa_supplicant
    ifconfig wlan0 default
    ifconfig wlan0 down
    echo "stop wpa_supplicant finish"
}

device_start_wpa_supplicant()
{
    if [ ! -f $WPA_SUPPLICANT_WORK_CFG_PATH ];then
        cp $WPA_SUPPLICANT_DEF_CFG_PATH $WPA_SUPPLICANT_WORK_CFG_PATH
        chmod 777 $WPA_SUPPLICANT_WORK_CFG_PATH
    fi

    if [ -n "$1" ];then
        busybox sed -i "s/^country=.*/country=$1/" $WPA_SUPPLICANT_WORK_CFG_PATH
    fi

    wpa_supplicant -i wlan0 -Dnl80211 -c $WPA_SUPPLICANT_WORK_CFG_PATH -B -ddd
    echo "start wpa_supplicant finish"
}

#--------------------------------------------------------------------------------------
# function: device_start_service_pre
#
#
#-------------------------------------------------------------------------------------
device_start_service_pre()
{
    device_stop_hostapd
    device_stop_wpa_supplicant
}

#--------------------------------------------------------------------------------------
# function: bcm_device_connect_ap
#
# $1 ssid, $2 passwd
#-------------------------------------------------------------------------------------
device_connect_ap()
{
    wpa_cli -i wlan0 disable_network 0
    wpa_cli -i wlan0 remove_network 0
    wpa_cli -i wlan0 ap_scan 1
    wpa_cli -i wlan0 add_network
    wpa_cli -i wlan0 set_network 0 ssid \'\"$1\"\'

    if [ -n $2 ];then
        wpa_cli -i wlan0 set_network 0 psk \'\"$2\"\'
    else
        wpa_cli -i wlan0 set_network 0 key_mgmt NONE
    fi

    wpa_cli -i wlan0 select_network 0
    wpa_cli -i wlan0 enable_network 0
    usleep 300000

    i=1
    while(( $i<=20 ))
    do
        wpa_state="$(wpa_cli -i wlan0 status | grep wpa_state)"
        val=${wpa_state#*=}

        if [[ "$val" = "COMPLETED" ]];then
            echo > /tmp/wifi_bss_mgmt.txt
            echo 0 > /tmp/wifi_bss_mgmt.txt
            break
        fi

        let i++
        usleep 500000
    done

    if [ $i -gt 20 ];then
        echo > /tmp/wifi_bss_mgmt.txt
        echo -1 > /tmp/wifi_bss_mgmt.txt
    else
        busybox killall udhcpc
        busybox udhcpc -b -i wlan0 -A 1
        usleep 100000
    fi
    echo "connect ap finish"
}

device_get_stats()
{
    cat /proc/net/dev | grep wlan0 | busybox awk '{print $2, $10}' > /tmp/wifi_bss_mgmt.txt
}

###########platform:eagle2, chip type: broadcom43752 and cypress43455, function define###########

bcm_pcie_power_on()
{
    mode_str=$(cat /sys/devices/platform/soc/f8100000.apb/f9b10000.pcie0/mode)
    if [ "$mode_str" = "high" ];then
        echo pcie power on
        echo low > /sys/devices/platform/soc/f8100000.apb/f9b10000.pcie0/mode
        usleep 500000
    fi
}

#---------------------------------------------------------------------------------------
# function: bcm_device_insmod_ko
#
# $1 fw_nv_flag(to select nvram, 0:NVRAM_CE, 1:NVRAM), $2 mac addr
# $3 alpha(to judge country code compliance, 0:ok,-1:fail), $4 $5 country code, $6 chip type
# $7 opt cpufreq flag(0: not opt cpufreq, 1: opt cpufreq)
# $8 bss_type(0: WIFI_BSS_TYPE_AP, 1: WIFI_BSS_TYPE_STA, 2: WIFI_BSS_TYPE_P2P_GO)
#---------------------------------------------------------------------------------------
bcm_device_insmod_ko()
{
    driver_name=$(lsmod | grep bcmdhd)
    if [ -n "$driver_name" ];then
        if [ $8 -eq 0 ];then
            ifconfig wlan0 192.168.2.1 up
        else
            ifconfig wlan0 up
        fi
        ifconfig wlan0 hw ether $2
        wl country $4$5
        wifi_download_param_opt $7
        echo "already insmod ko"
        exit 0
    fi

    _nvram_path=$BCM_NVRAM_PATH

    BCM_KO_PATH=`find /lib/modules -name bcmdhd.ko`
    if [ -e /data/misc/camera/crc_error ];then
        insmod $BCM_KO_PATH nvram_path=$BCM_NVRAM_LOW_POWER_PATH
    else
        insmod $BCM_KO_PATH
    fi

    wifi_download_param_opt $7

    ifconfig wlan0 192.168.2.1 up
    ifconfig wlan0 hw ether $2
    wl country $4$5
    echo "insmod ko success"
}

bcm_device_rmmod_ko()
{
    wl down
    ifconfig wlan0 down
    rmmod bcmdhd

    echo "rmmod ko finish"
}

bcm_start_wifi_set_cw()
{
    if [ $1 -eq 1 ];then
        wl cwmin 1
        wl cwmax 256
    fi
}

#--------------------------------------------------------------------------------------
# function: bcm_set_wireless_test_insmod
#
# $1 chip type 0:broadcom43752 1:cypress43455 2: broadcom43456
#--------------------------------------------------------------------------------------
bcm_set_wireless_test_insmod()
{
    driver_name=$(lsmod | grep bcmdhd)

    ifconfig wlan0 down

    if [ $1 -eq 0 ];then
        echo -n $BCM_FW43752_MFG_PATH > /sys/module/bcmdhd/parameters/firmware_path
        echo -n $BCM_NVRAM_PATH > /sys/module/bcmdhd/parameters/nvram_path
        echo -n $BCM_CLM_BLOB43752_PATH > /sys/module/bcmdhd/parameters/clm_path
    elif [ $1 -eq 1 ];then
        usleep 150000
        insmod $BCM_KO_PATH firmware_path=$BCM_FW_MFG_PATH nvram_path=$BCM_NVRAM_PATH clm_path=$BCM_CLM_BLOB_PATH #in ac101(cypress43455), not have clm_path
        cp $CYP_NVRAM_PATH $CYP_NVRAM_WORK_PATH
    elif [ $1 -eq 2 ];then
#        insmod $BCM_KO_PATH firmware_path=$BCM_FW43456_MFG_PATH nvram_path=$BCM_NVRAM_PATH clm_path=$BCM_CLM_BLOB43456_PATH dhd_poll=1
        echo -n $BCM_FW43456_MFG_PATH > /sys/module/bcmdhd/parameters/firmware_path
        echo -n $BCM_NVRAM_PATH > /sys/module/bcmdhd/parameters/nvram_path
        echo -n $BCM_CLM_BLOB43456_PATH > /sys/module/bcmdhd/parameters/clm_path
    fi

    ifconfig wlan0 192.168.2.1 up
    usleep 200000

    echo > /tmp/wifi_bss_mgmt.txt
    echo 1 > /tmp/wifi_bss_mgmt.txt
    echo "insmod ko, add fw blob finish"
}

#----------------------------------------------------------------------------------------
# function: bcm_pkteng_init
#
# $1 operation_type, $2 band, $3 band_width, $4 channel, $5 ant
#----------------------------------------------------------------------------------------

bcm_pkteng_init()
{
    wl down
    wl up
    wl mpc 0
    wl scansuppress 0
    wl phy_watchdog 0
    wl country ALL
    wl bw_cap 2g 3
    wl btc_mode 0

    if [ $2 -eq 0 ];then
        wl band b
    else
        wl band a
    fi

    if [[ $2 -eq 0 ]] && [[ $3 -eq 40 ]];then
        wl mimo_bw_cap 1
        if [ $4 -le 6 ];then
            wl chanspec $4"l"
        else
            wl chanspec $4"u"
        fi
    else
        wl chanspec $4/$3
    fi


    if [ $5 -gt 0 ];then
        if [ $5 -le 3 ];then
            if [[ $1 -eq 1 ]] || [[ $1 -eq 6 ]];then
                wl txchain $5
                wl rxchain $5
            elif [ $1 -eq 2 ];then
                wl txchain $5
                wl rxchain $5
            fi
        fi
    fi

    wl phy_forcecal 1
    wl scansuppress 1
    wl phy_txpwrctrl 1

    echo "bcm_pkteng_init finish"
}

#-----------------------------------------------------------------------------------
# function: judge_ant_and_channel
#
# $1 band, $2 channel, $3 ant
#-----------------------------------------------------------------------------------
judge_ant_and_channel()
{
    if [ $3 -gt 3 ];then
        echo "bad ant, ant > 3"
        echo -1 > /tmp/wifi_bss_mgmt_ret.txt
        exit 1
    fi

    if [[ $1 -eq 0 ]] && [[ $2 -gt 14 ]];then
        echo "2g band, but channel > 14"
        echo -1 > /tmp/wifi_bss_mgmt_ret.txt
        exit 1
    elif [[ $1 -eq 1 ]] && ([[ $2 -lt 149 ]] || [[ $2 -gt 165 ]]) && ([[ $2 -lt 36 ]] || [[ $2 -gt 48 ]]);then
        echo "5g band, but channel not between 149~165 or 36~48"
        echo -1 > /tmp/wifi_bss_mgmt_ret.txt
        exit 1
    fi
}

#----------------------------------------------------------------------------------------
# function:bcm_set_wireless_test_real_handle
#
# $1 operation_type, $2 band, $3 band_width, $4 channel, $5 ant, $6 spatial_stream
# $7 rate_mode, $8 rate, $9 power, ${10} interval, ${11} pkt_length, ${12} tx_packet_num
#----------------------------------------------------------------------------------------

bcm_set_wireless_test_real_handle()
{
    judge_ant_and_channel $2 $4 $5

    echo "param judge finish"

    case $1 in #operation_type
    1|6) # tx tx_tone
        spatial_stream=$6
        band_width=$3
        interval=${10}
        pkt_length=${11}
        rate_str=

        if [ $2 -eq 0 ];then
            rate_str=2g_rate
        elif [ $2 -eq 1 ];then
            rate_str=5g_rate
        else
            echo -1 > /tmp/wifi_bss_mgmt_ret.txt
            echo "band error"
            exit 1
        fi

        bcm_pkteng_init $1 $2 $3 $4 $5
        
        if [ $6 -le 0 ];then
            spatial_stream=1            
        fi

        if [ $3 -le 20 ];then
            band_width=20
        fi

        case $7 in
        0|1|2) #802.11b, 802.11g, 802.11a
            wl "$rate_str" -r $8 -b $band_width
            ;;
        3) #802.11n
            wl "$rate_str" -h $8 -b $band_width
            ;;
        4) #802.11ac
            wl "$rate_str" -v $8 -b $band_width --ldpc -s $spatial_stream
            ;;
        5) #802.11ax
            wl "$rate_str" -e $8 -b $band_width --ldpc -s $spatial_stream
            wl longpkt 0
            ;;
        *)
            echo -1 > /tmp/wifi_bss_mgmt_ret.txt
            echo "rate_mode error"
            exit 1
            ;; 
        esac

        if [ $9 -eq 0 ];then
            wl txpwr1 -1
        else
            if [[ $9 -ge -32 ]] && [[ $9 -le 31 ]];then
                wl txpwr1 -o -d $9
            else
                wl txpwr1 -o -q $9
            fi
        fi

        if [ ${10} -le 0 ];then
            interval=100
        fi

        if [ ${11} -le 0 ];then
            pkt_length=1024
        fi

        wl pkteng_start 00:11:22:33:44:55 tx $interval $pkt_length ${12}
        wl phy_forcecal 1

        if [ $1 -eq 6 ];then
            wl down
            wl country ALL

            if [ $2 -eq 0 ];then
                wl band b
            else
                wl band a
            fi

            wl mpc 0
            wl up
            wl phy_txpwrctrl 0
            wl phy_txpwrindex 120
            wl phy_tx_tone 10
        fi

        echo "set wireless handle tx finish"
        ;;
    2) # rx
        bcm_pkteng_init $1 $2 $3 $4 $5
        wl pkteng_start 00:11:22:33:44:55 rx
        wl reset_cnts
        echo "set wireless handle rx finish"
        ;;
    8|10) # noise floor
        ;;
    9) #wifi_carrier
        wl fqacurcy 0
        wl down
        wl mpc 0

        if [ $2 -eq 0 ];then
            wl band b
        else
            wl band a
        fi

        wl up
        wl phy_txpwrindex $9 $9
        wl out
        wl fqacurcy $4
        echo "set wireless handle wifi_carrier finish"
        ;;
    *)
        echo "operation_type error"
        exit 1
        ;;
    esac

    echo 0 > /tmp/wifi_bss_mgmt_ret.txt
    echo "bcm_set_wireless_test_real_handle finish"
}

#---------------------------------------------------------------------
# function: bcm_get_wireless_test_real_handle
#
# $1 operation_type, $2 ant, $3 band, $4 channel
#---------------------------------------------------------------------

bcm_get_wireless_test_real_handle()
{
    #judge_ant_and_channel $3 $4 $2

    case $1 in # operation_type
    2) # rx
        wl counters |grep pktengrxdmcast | busybox awk '{print $2+$4}' > /tmp/wifi_bss_mgmt.txt
        ;;
    8) # wifi noise floor 2x2
        judge_ant_and_channel $3 $4 $2
        wl down
        wl mpc 0
        wl PM 0
        wl rxchain $2

        if [ $3 -eq 0 ];then
            wl band b
        else
            wl band a
        fi
        
        wl channel $4
        wl up
        wl phy_forcecal 1

        if [ $2 -eq 1 ];then
            wl phy_rxiqest  | busybox awk '{print $1}' > /tmp/wifi_bss_mgmt.txt
        elif [ $2 -eq 2 ];then
            wl phy_rxiqest  | busybox awk '{print $2}' > /tmp/wifi_bss_mgmt.txt
        else
            echo -1 > /tmp/wifi_bss_mgmt_ret.txt
            echo "bad ant, ant >= 3"
            exit 1
        fi
        ;;
    10) # wifi noise floor 1x1
        judge_ant_and_channel $3 $4 $2
        wl down
        wl mpc 0
        wl PM 0
        wl phy_watchdog 0
        wl country ALL
        wl scansuppress 1
        wl btc_mode 0

        if [ $3 -eq 0 ];then
            wl band b
        else
            wl band a
        fi

        wl chanspec $4/20
        wl up
        wl rxchain 1
        wl phy_forcecal 1
        wl phy_deaf 1
        wl phy_rxiqest -s 15 -r 1 -i 1 -n 10 | tr -d "[a-z] && [A-Z]" > /tmp/wifi_bss_mgmt.txt
        ;;
    *)
        echo "operation_type error"
        exit 1
        ;;
    esac

    echo 0 > /tmp/wifi_bss_mgmt_ret.txt
}

#---------------------------------------------------------------------------------
# function: bcm_bt_test_tx_tone
#
# $1 chip type, $2 param str
#---------------------------------------------------------------------------------
bcm_bt_test_tx_tone()
{
    APP_UIPC_SIMPLE_APP_ORI=$BCM_BT_APP_DEF_PATH
    APP_UIPC_SIMPLE_APP=$BCM_BT_APP_WORK_PATH
    APP_UIPC_BT_PATH=/data/misc/bluetooth/

    if [ $1 -eq 1 ];then
        APP_UIPC_SIMPLE_APP_ORI=$CYP_BT_APP_DEF_PATH
        APP_UIPC_SIMPLE_APP=$CYP_BT_APP_WORK_PATH
        APP_UIPC_BT_PATH=/tmp/
    fi

    if [ ! -f $APP_UIPC_SIMPLE_APP ];then
        cp $APP_UIPC_SIMPLE_APP_ORI $APP_UIPC_SIMPLE_APP
        chmod +x $APP_UIPC_SIMPLE_APP 
    fi

    # hci reset
    # cd $APP_UIPC_BT_PATH && ./simple_app --hci 030C00
    /system/bin/simple_app --hci 030C00
    # bt signal tone tx cfg
    # cd $APP_UIPC_BT_PATH && ./simple_app --vsc $2
    /system/bin/simple_app --vsc $2

    if [ $? == 0  ]; then
        echo "simple_app run success."
        exit 0
    else
        echo "simple_app run failed."
        exit 1
    fi
    echo "bcm bt test tx tone finish"
}

bcm_device_get_link_strength()
{
    link_cnt=$(wl assoclist | grep -c assoclist)
    if [ $link_cnt -eq 0 ];then
        echo -6 > /tmp/wifi_bss_mgmt_ret.txt
        echo "no device link to this eagle2 product"
        exit 1
    fi

    i=1
    while(( $i<=$link_cnt ))
    do
        mac_addr=$(wl assoclist | busybox awk 'NR=="'$i'" {print $2}')
        rssi=$(wl rssi $mac_addr)
        echo $rssi > /tmp/wifi_bss_mgmt.txt
        let i++
    done
    echo 0 > /tmp/wifi_bss_mgmt_ret.txt
}

bcm_device_get_wifi_quanlity()
{
    txframe=$(wl counters |grep txframe |busybox awk '{print $2, $4, $6, $8}')
    rxframe=$(wl counters |grep rxframe |busybox awk '{print $2, $4, $6}')
    echo "$txframe $rxframe" > /tmp/wifi_bss_mgmt.txt
}

#---------------------------------------------------------------------------------
# function: bcm_device_bcm_set_country
#
# $1 country code
#---------------------------------------------------------------------------------
bcm_device_bcm_set_country()
{
    wl country $1

    cnt=0
    while (( 1 ))
    do
        chan=`cat /sys/module/bcmdhd/parameters/best_2g_channel`
        if [ $chan -eq 0 ];then
            let cnt++
            usleep 100000
        else
            break
        fi

        if [ $cnt -gt 20 ];then
            break
        fi
    done
}

###########platform:e3t, chip type: uwe2652, function define###########

#---------------------------------------------------------------------------------
# function: uwe_device_insmod_ko
#
# $1 mac addr
#---------------------------------------------------------------------------------
uwe_device_insmod_ko()
{
    echo $1 > /data/misc/wifi/wifimac.txt

    driver_name=$(lsmod | grep uwe5622_bsp_sdio)
    if [ -z "$driver_name" ];then
        insmod /system/lib/modules/uwe5622_bsp_sdio.ko
    fi

    driver_name=$(lsmod | grep sprdwl_ng)
    if [ -z "$driver_name" ];then
        insmod /system/lib/modules/sprdwl_ng.ko
    fi

    wifi_download_param_opt $2

    ifconfig wlan0 up
    ifconfig wlan0 192.168.2.1

    echo "uwe device insmod ko finish"
}

uwe_device_rmmod_ko()
{
    driver_name=$(lsmod | grep sprdwl_ng | busybox awk '{print $1}')
    if [ -n "$driver_name" ]; then
        rmmod sprdwl_ng
    fi

    rely_num=$(lsmod | grep uwe5622_bsp_sdio | busybox awk '{print $3}')
    driver_name=$(lsmod | grep uwe5622_bsp_sdio | busybox awk '{print $1}')
    if [ "uwe5622_bsp_sdio" == "$driver_name" ] && [ 0 -eq $rely_num ]; then
        rmmod uwe5622_bsp_sdio
    fi
}

uwe_device_stop_wifi()
{
    busybox kill -9 `ps -A | busybox grep wpa_supplicant | busybox awk -F ' ' '{print $2}'`
    # busybox kill -9 `ps -A | busybox grep hostapd | busybox awk -F ' ' '{print $2}'`
    # ifconfig wlan0 down
    kill_udhcpd
    echo "uwe_device_stop_wifi finish"
}

uwe_device_get_wifi_quanlity()
{
    txframe=$(iwnpi wlan0 get_link_stat 1 |grep txframe |busybox awk '{print $2, $4, $6, $8}')
    rxframe=$(iwnpi wlan0 get_link_stat 1 |grep rxframe |busybox awk '{print $2, $4, $6}')
    echo "$txframe $rxframe" > /tmp/wifi_bss_mgmt.txt
}

uwe_insmod_bt_ko()
{
    driver_name=$(lsmod | grep uwe5622_bsp_sdio)
    if [ -z "$driver_name" ];then
        insmod /system/lib/modules/uwe5622_bsp_sdio.ko
    fi

    driver_name=$(lsmod | grep sprdbt_tty)
    if [ -z "$driver_name" ];then
        insmod /system/lib/modules/sprdbt_tty.ko
    fi
}

uwe_rmmod_bt_ko()
{
    driver_name=$(lsmod | grep sprdbt_tty | busybox awk '{print $1}')
    if [ -n "$driver_name" ]; then
        rmmod sprdbt_tty
    fi

    rely_num=$(lsmod | grep uwe5622_bsp_sdio | busybox awk '{print $3}')
    driver_name=$(lsmod | grep uwe5622_bsp_sdio | busybox awk '{print $1}')
    if [ "uwe5622_bsp_sdio" == "$driver_name" ] && [ 0 -eq $rely_num ]; then
        rmmod uwe5622_bsp_sdio
    fi
}
###########platform:e1e, chip type: qca6174a, function define###########

#---------------------------------------------------------------------------------
# function: qca_device_start_hostapd
#
# $1 channel, $2 cen_freq, $3 bandwidth, $4 direction
#---------------------------------------------------------------------------------
qca_device_start_hostapd()
{
    busybox sed -i 's/vht_oper_chwidth=.*/vht_oper_chwidth=0/' $QCA_WIFI_CFG_HOSTAPD_PATH
    busybox sed -i 's/vht_oper_centr_freq_seg0_idx=.*/vht_oper_centr_freq_seg0_idx=0/' $QCA_WIFI_CFG_HOSTAPD_PATH

    if [ $1 -lt 15 ];then
        busybox sed -i 's/hw_mode=.*/hw_mode=g/' $QCA_WIFI_CFG_HOSTAPD_PATH
        busybox sed -i 's/ieee80211ac=.*/ieee80211ac=0/' $QCA_WIFI_CFG_HOSTAPD_PATH
    else
        busybox sed -i 's/hw_mode=.*/hw_mode=a/' $QCA_WIFI_CFG_HOSTAPD_PATH
        busybox sed -i 's/ieee80211ac=.*/ieee80211ac=1/' $QCA_WIFI_CFG_HOSTAPD_PATH

        if [ $3 -eq 80 ];then
            busybox sed -i 's/vht_oper_chwidth=.*/vht_oper_chwidth=1/' $QCA_WIFI_CFG_HOSTAPD_PATH
            busybox sed -i "s/vht_oper_centr_freq_seg0_idx=.*/vht_oper_centr_freq_seg0_idx=$2/" $QCA_WIFI_CFG_HOSTAPD_PATH
        fi
    fi

    if [ $4 -eq 0 ];then
        busybox sed -i 's/ht_capab=.*/ht_capab=[HT20]/' $QCA_WIFI_CFG_HOSTAPD_PATH
    elif [ $4 -lt 0 ];then
        busybox sed -i 's/ht_capab=.*/ht_capab=[HT20][HT40-]/' $QCA_WIFI_CFG_HOSTAPD_PATH
    elif [ $4 -gt 0 ];then
        busybox sed -i 's/ht_capab=.*/ht_capab=[HT20][HT40+]/' $QCA_WIFI_CFG_HOSTAPD_PATH
    fi

    hostapd -B $UWE_WIFI_CFG_HOSTAPD_PATH

    echo "uwe device start hostapd finish"
}

qca_device_insmod_ko()
{
    insmod /system/lib/modules/wlan.ko
    usleep 800000
    ifconfig wlan0 up
    ifconfig wlan0 192.168.2.1
}

qca_device_start_wifi()
{
    cp -rf /tmp/scan_res /cali/wifi/scan_result.conf
    cp -rf /tmp/acs_result /cali/wifi/acs_info.conf
}

qca_device_stop_wifi()
{
    kill `ps | busybox grep wpa_supplicant | busybox awk -F ' ' '{print $2}'`
    kill `ps | busybox grep hostapd | busybox awk -F ' ' '{print $2}'`
    ifconfig wlan0 down
    rmmod wlan
    busybox pkill -f udhcpd
}

#------------------------------------------------------------------------------
# function: qca_device_set_wireless_test
#
# $1 operation_type. $2 rate_mode, $3 rate_index, $4 band_width,
# $5 freq, $6 ant, $7 power, $8 mfg_state
#------------------------------------------------------------------------------
qca_device_set_wireless_test()
{
    if [ $8 -eq 1 ];then
        ret=$(lsmod | busybox grep -c wlan)
        if [ $ret -eq 0 ];then
            rmmod wlan
            sleep 2
        fi

        ret=$(insmod /system/lib/modules/wlan.ko con_mode=5 qcombr_mode=0)
        if [ $ret -eq 0 ];then
            echo 1 > /tmp/wifi_bss_mgmt.txt
            echo 0 > /tmp/wifi_bss_mgmt_ret.txt
        else
            echo "insmod ko error"
            echo -1 > /tmp/wifi_bss_mgmt.txt
            echo -1 > /tmp/wifi_bss_mgmt_ret.txt
            exit 1
        fi 

        sleep 2
    fi

    myftm -x 0
    myftm -t 0

    ant=$6
    if [ $6 -ge 3 ];then
        ant=3
    fi

    case $2 in
    0) #802.11b
        /system/bin/myftm -M 4 -r $3 -f $5 -a $ant
        ;;
    1|2) #802.11g or 802.11a
        /system/bin/myftm -M 0 -r $3 -f $5 -a $ant
        ;;
    3) #802.11n
        if [ $4 -eq 20 ];then
            /system/bin/myftm -M 1 -r $3 -f $5 -a $ant
        elif [ $4 -eq 40 ];then
            /system/bin/myftm -M 2 -r $3 -f $5 -a $ant
        fi
        ;;
    4) #802.11ac
        if [ $4 -eq 20 ];then
            /system/bin/myftm -M 5 -r $3 -f $5 -a $ant
        elif [ $4 -eq 40 ];then
            /system/bin/myftm -M 6 -r $3 -f $5 -a $ant
        elif [ $4 -eq 80 ];then
            /system/bin/myftm -M 8 -r $3 -f $5 -a $ant
        fi
        ;;
    *)
        echo "rate mode error"
        exit 1
        ;;
    esac

    if [ $1 -eq 1 ];then #tx
        if [ $7 -ge 0 ];then
            /system/bin/myftm -c 0 -p $7 -t 3
        else
            /system/bin/myftm -c 2 -t 3
        fi
    elif [ $1 -eq 2 ];then #rx
        /system/bin/myftm -x 1
    fi

    echo 0 > /tmp/wifi_bss_mgmt.txt
}

############################### main handle body #######################

case $1 in #platform type
0) #platform common
    case $2 in #function name
    0) #stop hostapd
        device_stop_hostapd
        ;;
    1) #device_start_hostapd
        device_start_hostapd $3 "$4" $5 $6
        ;;
    2) # device_stop_wpa_supplicant
        device_stop_wpa_supplicant $3
        ;;
    3) #device_start_wpa_supplicant
        device_start_wpa_supplicant $3
        ;;
    5) #device_connect_ap
        device_connect_ap $3 $4
        ;;
    13) #device_get_stats
        device_get_stats
        ;;
    17) #device_start_service_pre
        device_start_service_pre
        ;;
    esac
    ;;
1) #platform_eagle2
    case $2 in #chip vendor
    0) #broadcom
        case $3 in #chip type
        0|2) #broadcom43752 broadcom43456
            case $4 in #function name
            6) #device_insmod_ko
                bcm_device_insmod_ko $5 $6 $7 $8 $9 $3 ${10} ${11}
                ;;
            7) #device_rmmod_ko
                bcm_device_rmmod_ko
                ;;
            8) #device_start_wifi
                ;;
            9) #device_stop_wifi
                ;;
            10) #device_set_wireless_test
                if [ $5 -eq 1 ];then
                    bcm_set_wireless_test_insmod $3
                fi

                wl pkteng_stop tx
                wl pkteng_stop rx

                bcm_set_wireless_test_real_handle $6 $7 $8 $9 ${10} ${11} ${12} ${13} ${14} ${15} ${16} ${17}
                ;;
            11) #device_get_wireless_test
                bcm_get_wireless_test_real_handle $5 $6 $7 $8
                ;;
            12) #device_get_link_strength
                bcm_device_get_link_strength
                ;;
            14) #device_get_wifi_quanlity
                bcm_device_get_wifi_quanlity
                ;;
            16) #device_bcm_set_country
                bcm_device_bcm_set_country $5
                ;;
            30) #bt_test_tx_tone
                bcm_bt_test_tx_tone $3 $5
                ;;
            *)
                echo "function name error"
                exit 1
                ;;
            esac
            ;;
        *)
            echo "chip type error"
            exit 1
            ;;
        esac
        ;;
    1) #unisoc
        case $3 in #chip type
        0) #uwe2652
            case $4 in # function name
            6) #device_insmod_ko
                uwe_device_insmod_ko $5 $6
                ;;
            7) #device_rmmod_ko
                uwe_device_rmmod_ko
                ;;
            9) #device_stop_wifi
                uwe_device_stop_wifi
                ;;
            14) # device_get_wifi_quanlity
                uwe_device_get_wifi_quanlity
                ;;
            31) # insmod_bt_ko
                uwe_insmod_bt_ko
                ;;
            32) # rmmod_bt_ko
                uwe_rmmod_bt_ko
                ;;
            *)
                echo "function name error"
                exit 1
                ;;
            esac
            ;;
        *)
            echo "chip type error"
            exit 1
            ;;
        esac
        ;;
	2) #qualcomm
	    case $3 in #chip type
        0) #qca6174a
            case $4 in
            1) #device_start_hostapd
                qca_device_start_hostapd $5 $6 $7 $8
                ;;
            6) #device_insmod_ko
                qca_device_insmod_ko
                ;;
            8) #device_start_wifi
                qca_device_start_wifi
                ;;
            9) #device_stop_wifi
                qca_device_stop_wifi
                ;;
            10) #device_set_wireless_test
                qca_device_set_wireless_test $5 $6 $7 $8 $9 ${10} ${11} ${12}
                ;;
            *)
                echo "function name error"
                exit 1
                ;;
            esac
            ;;
        *)
            echo "chip type error"
            exit 1
            ;;
        esac
        ;;
    *)
        echo "chip vendor error"
        exit 1
    esac
    ;;
2) #amba
    ;;
*)
    echo "platform type error"
    exit 1
    ;;
esac

