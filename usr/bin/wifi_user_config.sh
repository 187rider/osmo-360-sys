#! /bin/sh

# control socket directory
CONTROL_DIR=/data/misc/wifi
BLUETOOTH_DIR=/data/misc/bluetooth
FACTORY_DIR=/cali/wireless/wifi_factory

SOCKET_PATH=/data/misc/wifi/sockets

#configuration files
AP_PSK_CONF=$CONTROL_DIR/hostapd.psk
WIFI_MAC_CFG_FILE=$CONTROL_DIR/softmac.bin
DEVICE_ID_WORK_PATH=$CONTROL_DIR/device_id.txt
DEVICE_ID_DEF_PATH=/factory_data/device_id.txt

#factory file
FACTORY_WIFI_MAC_ADDR=$FACTORY_DIR/softmac.bin

if [ ! -d $CONTROL_DIR ]; then
    echo "directory $CONTROL_DIR do not exist, create it"
    mkdir -p $CONTROL_DIR
    chmod 777 $CONTROL_DIR
fi

if [ ! -d $BLUETOOTH_DIR ]; then
    echo "directory $BLUETOOTH_DIR do not exist, create it"
    mkdir -p $BLUETOOTH_DIR
    chmod 777 $BLUETOOTH_DIR
fi

if [ ! -d $SOCKET_PATH ]; then
    echo "directory $SOCKET_PATH do not exist, create it"
    mkdir -p $SOCKET_PATH
    chmod 777 $SOCKET_PATH
fi

if [ ! -d $FACTORY_DIR ]; then
    echo "directory $FACTORY_DIR do not exist, create it"
    mkdir -p $FACTORY_DIR
    chmod 777 $FACTORY_DIR
fi

if [[ -f $DEVICE_ID_DEF_PATH ]];then
    cp $DEVICE_ID_DEF_PATH $DEVICE_ID_WORK_PATH
    chmod 777 $DEVICE_ID_WORK_PATH
fi

if [[ ! -f $DEVICE_ID_WORK_PATH ]] && [[ -f $DEVICE_ID_DEF_PATH ]];then
    rm $CONTROL_DIR/user_config.conf
fi

if [ `ps | busybox grep -v grep | busybox grep -c wpa_supplicant` -gt 0 ]; then
    echo "kill process wpa_supplicant"
    killall -KILL wpa_supplicant
fi

if [ `ps | busybox grep -v grep | busybox grep -c hostapd` -gt 0 ]; then
    echo "kill process hostapd"
    killall -KILL hostapd
fi

udhcpd_pid=`ps | grep -v grep | grep udhcpd_wifi | busybox awk -F ' ' '{print $1}'`
if [ $? == 0 ]; then
    if [ $udhcpd_pid -gt 0 ]; then
        echo "kill process udhcpd_wifi $udhcpd_pid"
        kill -9 $udhcpd_pid
    fi
fi

#if [ `lsmod | busybox grep -v grep | busybox grep -c bcmdhd` -gt 0 ]; then
#    rmmod bcmdhd
#fi

# Check softmac set in factory
if [ -f $FACTORY_WIFI_MAC_ADDR ]; then
    cp $FACTORY_WIFI_MAC_ADDR $WIFI_MAC_CFG_FILE
    chmod 666 $WIFI_MAC_CFG_FILE
    echo "factory wifi mac addr exist, use it"
fi

FACTORY_WIFI_CONF=$FACTORY_DIR/wifi.config
# Check ssid/psk set in factory
if [ -f "$FACTORY_WIFI_CONF" ]; then
    cat $FACTORY_WIFI_CONF | busybox grep psk
    if [ $? == 0 ]
    then
        AP_PSK=`cat $FACTORY_WIFI_CONF | busybox grep psk | busybox awk -F '=' '{print $2}'`
    fi
    cat $FACTORY_WIFI_CONF | busybox grep ssid
    if [ $? == 0 ]
    then
        AP_SSID=`cat $FACTORY_WIFI_CONF | busybox grep ssid | busybox awk -F '=' '{print $2}'`
    fi
    echo "NEW_PSK $AP_PSK, NEW_SSID $AP_SSID"
fi

if [ ! -f "$AP_PSK_CONF" ]; then
    touch $AP_PSK_CONF
    chmod 666 $AP_PSK_CONF
fi

# Add config of AC103
size=`ls -l $BLUETOOTH_DIR/bt_configure_pskey.ini | busybox awk '{ print $5 }'`
if [ ! -f $BLUETOOTH_DIR/bt_configure_pskey.ini ] || [ $size == 0 ]
then
        cp /vendor/firmware/bt_configure_pskey.ini $BLUETOOTH_DIR/bt_configure_pskey.ini
fi

size=`ls -l $BLUETOOTH_DIR/bt_configure_rf.ini | busybox awk '{ print $5 }'`
if [ ! -f $BLUETOOTH_DIR/bt_configure_rf.ini ] || [ $size == 0 ]
then
        cp /vendor/firmware/bt_configure_rf.ini $BLUETOOTH_DIR/bt_configure_rf.ini
fi

size=`ls -l $CONTROL_DIR/wifi_board_config.ini | busybox awk '{ print $5 }'`
if [ ! -f $CONTROL_DIR/wifi_board_config.ini ] || [ $size == 0 ]
then
        cp /vendor/firmware/wifi_board_config.ini $CONTROL_DIR/wifi_board_config.ini
fi

## cfg dhcp server
echo > /tmp/udhcpd.leases
chmod 666 /tmp/udhcpd.leases

# Unlink the unused PF_UNIX socket
rm -rf $SOCKET_PATH/*

chmod 777 /data/misc/ -R

sync

exit 0
