#! /bin/sh

### BEGIN INFO
# Used to init wifi/bt related config
# Provider: caesar.li
### END INFO

# control socket directory
CONTROL_DIR=/data/misc/wifi
CFG_DIR=/cali/connectivity/wifi
BT_CFG_DIR=/cali/connectivity/bt

mkdir -p /data/misc/wifi
mkdir -p /cali/connectivity/wifi
mkdir -p /cali/connectivity/bt
mkdir -p /tmp/run
mkdir -p /data/misc/dhcp/
if [ ! -d $CONTROL_DIR ]; then
    echo "directory $CONTROL_DIR does not exist"
    exit 1
fi

if [ ! -d $CFG_DIR ]; then
    echo "directory $CFG_DIR doen not exist, create it"
    mkdir $CFG_DIR
fi

if [ ! -d $BT_CFG_DIR ]; then
    echo "directory $BT_CFG_DIR doen not exist, create it"
    mkdir $BT_CFG_DIR
fi


size=`ls -l /cali/connectivity/bt/bt_configure_pskey.ini | busybox awk '{ print $5 }'`
if [ ! -f /cali/connectivity/bt/bt_configure_pskey.ini ] || [ $size == 0 ]
then
        cp /vendor/connectivity/bt/bt_configure_pskey.ini /cali/connectivity/bt/bt_configure_pskey.ini
fi

size=`ls -l /cali/connectivity/bt/bt_configure_rf.ini | busybox awk '{ print $5 }'`
if [ ! -f /cali/connectivity/bt/bt_configure_rf.ini ] || [ $size == 0 ]
then
        cp /vendor/connectivity/bt/bt_configure_rf.ini /cali/connectivity/bt/bt_configure_rf.ini
fi

size=`ls -l /cali/connectivity/wifi/udhcpd_wlan0.conf | busybox awk '{ print $5 }'`
if [ ! -f /cali/connectivity/wifi/udhcpd_wlan0.conf ] || [ $size == 0 ]
then
        cp /vendor/connectivity/wifi/udhcpd_wlan0.conf /cali/connectivity/wifi/udhcpd_wlan0.conf
fi

size=`ls -l /cali/connectivity/wifi/wifi_board_config.ini | busybox awk '{ print $5 }'`
if [ ! -f /cali/connectivity/wifi/wifi_board_config.ini ] || [ $size == 0 ]
then
        cp /vendor/connectivity/wifi/wifi_board_config.ini /cali/connectivity/wifi/wifi_board_config.ini
fi

size=`ls -l /cali/connectivity/wifi/wpa_supplicant.conf | busybox awk '{ print $5 }'`
if [ ! -f /cali/connectivity/wifi/wpa_supplicant.conf ] || [ $size == 0 ]
then
        cp /vendor/connectivity/wifi/wpa_supplicant.conf /cali/connectivity/wifi/wpa_supplicant.conf
fi


# factory data
FACTORY_DIR=/factory_data/wifi

# Wi-Fi & BT MAC addr file
WIFI_MAC_FILE=$FACTORY_DIR/wlan_mac.bin
BT_MAC_FILE=$FACTORY_DIR/bt_nv.bin
CALI_DIR=/cali/connectivity/wifi
MOD_NAME=wlan

if [ `ps | busybox grep -c wpa_supplicant` -gt 0 ]; then
    echo "kill process wpa_supplicant"
    busybox pgrep wpa_supplicant | busybox xargs kill
fi

if [ `ps | busybox grep -c hostapd` -gt 0 ]; then
    echo "kill process hostapd"
    busybox pgrep hostapd | busybox xargs kill
fi

if [ `lsmod | busybox grep -c $MOD_NAME` -gt 0 ]; then
    rmmod $MOD_NAME
fi

if [ ! -d $CALI_DIR ]; then
    mkdir -p $CALI_DIR
fi

# WIFI MAC address
if [ -f $WIFI_MAC_FILE ]; then
    echo "find factory wifi mac file"
    cp $WIFI_MAC_FILE $CALI_DIR/wlan_mac.bin
fi

# BT MAC address
if [ -f $BT_MAC_FILE ]; then
    echo "find factory bt mac file"
    cp $BT_MAC_FILE $CALI_DIR/bt_nv.bin
fi

chown wifi:wifi $CONTROL_DIR
chmod 766 /cali -R

sync


## turn on dhcp server
if [ ! -d $DHCP_DIR ]
then
    mkdir -p $DHCP_DIR
fi
echo > /data/misc/dhcp/udhcpd.leases
# busybox udhcpd /etc/udhcpd_wifi.conf

# Unlink the unused PF_UNIX socket
#rm /data/misc/wifi/sockets/*
sync

exit 0

