bt_status_file=/data/misc/bluetooth/bt-daemon-socket

sleep 1
if [ ! -e "$bt_status_file" ]; then
        echo "test connect to bt failed"
        echo 1 > /tmp/bt_status
        rm -rf /data/misc/bluetooth/bt-daemon-socket
        exit 1
else
        echo "test connect to bt success"
        echo 0 > /tmp/bt_status
        rm -rf /data/misc/bluetooth/bt-daemon-socket
        exit 0
fi

