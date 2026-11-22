# [TC] 2023-09-18, artur.qin, patch id: 302609, USB-add-usb-composition-8002-Mass_storage-adb
# [TC MODIFIED_BY_DJI_START] USB-add-usb-composition-8002-Mass_storage-adb

cd /usr/bin
/usr/bin/usb_composition_switch 8002 n y y n

8001: mass_storage
8002: mass_storage,adb
8003: rndis,adb
8004: uac,uvc,adb


# [TC MODIFIED_BY_DJI_END] USB-add-usb-composition-8002-Mass_storage-adb

