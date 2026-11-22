#!/bin/sh

LOCAL_ECHO=$(which echo)
msm_serial=`cat /sys/devices/soc0/serial_number`
msm_serial_hex=`printf %08X $msm_serial`
product_string="Osmo360_SN:$msm_serial_hex"

init_product_string() {
	echo "$product_string" > /sys/kernel/config/usb_gadget/g1/strings/0x409/product
	${LOCAL_ECHO} "current_product ${product_string}" > /dev/kmsg
}

init_iProduct() {
	if [ -d /sys/class/android_usb/android0 ]
	then
		${LOCAL_ECHO} "$product_string" > /sys/class/android_usb/android0/iProduct
	fi
}

config_msc_lun() {
	mkdir functions/mass_storage.0
	mkdir functions/mass_storage.0/lun.1
	${LOCAL_ECHO} "set two lun for SD/ufs" > /dev/kmsg
}

config_usb_storage_delay_use() {
	if [ -e /sys/module/usb_storage/parameters/delay_use ]
	then
		${LOCAL_ECHO} "not change usb_storage delay_use" > /dev/kmsg
	fi
}

init_uvc() {
	#
	# Initialize UVC conifguration.
	#
	if [ -d /sys/kernel/config/usb_gadget/g1/functions/uvc.0 ]; then
		cd /sys/kernel/config/usb_gadget/g1/functions/uvc.0

		# [DJI MODIFIED_BY_DJI_START] set uvc name
		echo "Osmo360" > function_name
		# [DJI MODIFIED_BY_DJI_END] set uvc name
		# [DJI MODIFIED_BY_DJI_START] solve macos black screen with usb3.0
		echo 1024 > streaming_maxpacket
		# [DJI MODIFIED_BY_DJI_END] solve macos black screen with usb3.0
		# [TC MODIFIED_BY_DJI_START] change uvc to iso
		# [DJI MODIFIED_BY_DJI_START] improve mjpeg and h264 screen distortion issues
		echo 0 > streaming_maxburst
		# [DJI MODIFIED_BY_DJI_END] improve mjpeg and h264 screen distortion issues
		echo 0 > streaming_bulk
		# [TC MODIFIED_BY_DJI_END] change uvc to iso
		mkdir control/header/h
		ln -s control/header/h control/class/fs/
		ln -s control/header/h control/class/ss

		# [TC MODIFIED_BY_DJI_START] change uvc to iso
		# mkdir -p streaming/uncompressed/u/360p
		# echo -e "166666\n333333\n666666\n1000000\n5000000\n" > streaming/uncompressed/u/360p/dwFrameInterval
		# echo 333333 > streaming/uncompressed/u/360p/dwDefaultFrameInterval

		# mkdir -p streaming/uncompressed/u/720p
		# echo 1280 > streaming/uncompressed/u/720p/wWidth
		# echo 720 > streaming/uncompressed/u/720p/wHeight
		# echo 29491200 > streaming/uncompressed/u/720p/dwMinBitRate
		# echo 29491200 > streaming/uncompressed/u/720p/dwMaxBitRate
		# echo 1843200 > streaming/uncompressed/u/720p/dwMaxVideoFrameBufferSize
		# echo 333333 > streaming/uncompressed/u/720p/dwDefaultFrameInterval
		# echo -e "166666\n333333\n666666\n1000000\n5000000\n" > streaming/uncompressed/u/720p/dwFrameInterval

		# mkdir -p streaming/uncompressed/u/1080p
		# echo 1920 > streaming/uncompressed/u/1080p/wWidth
		# echo 1080 > streaming/uncompressed/u/1080p/wHeight
		# echo 66355200 > streaming/uncompressed/u/1080p/dwMinBitRate
		# echo 995328000 > streaming/uncompressed/u/1080p/dwMaxBitRate
		# echo 4147200 > streaming/uncompressed/u/1080p/dwMaxVideoFrameBufferSize
		# echo 333333 > streaming/uncompressed/u/1080p/dwDefaultFrameInterval
		# echo -e "166666\n333333\n666666\n1000000\n5000000\n" > streaming/uncompressed/u/1080p/dwFrameInterval

		# mkdir -p streaming/uncompressed/u1/360p
		# echo -e "166666\n333333\n666666\n1000000\n5000000\n" > streaming/uncompressed/u1/360p/dwFrameInterval
		# echo 333333 > streaming/uncompressed/u1/360p/dwDefaultFrameInterval

		# mkdir -p streaming/mjpeg/m1/360p
		# echo 640 > streaming/mjpeg/m1/360p/wWidth
		# echo 360 > streaming/mjpeg/m1/360p/wHeight
		# echo 460800   > streaming/mjpeg/m1/360p/dwMaxVideoFrameBufferSize
		# echo 18432000  > streaming/mjpeg/m1/360p/dwMinBitRate
		# echo 55296000 > streaming/mjpeg/m1/360p/dwMaxBitRate
		# echo -e "166666\n333333\n666666\n1000000\n5000000\n" > streaming/mjpeg/m1/360p/dwFrameInterval
		# echo 333333 > streaming/mjpeg/m1/360p/dwDefaultFrameInterval
		# [TC MODIFIED_BY_DJI_START] change uvc to iso

		mkdir -p streaming/mjpeg/m1/720p
		echo 1280 > streaming/mjpeg/m1/720p/wWidth
		echo 720 > streaming/mjpeg/m1/720p/wHeight
		echo 32000000 > streaming/mjpeg/m1/720p/dwMinBitRate
		echo 96000000 > streaming/mjpeg/m1/720p/dwMaxBitRate
		echo 1843200 > streaming/mjpeg/m1/720p/dwMaxVideoFrameBufferSize
		echo 333333 > streaming/mjpeg/m1/720p/dwDefaultFrameInterval
		# [TC MODIFIED_BY_DJI_START] change uvc to iso
		# [DJI MODIFIED_BY_DJI_START] add uvc 25fps enum
		echo -e "333333\n400000\n" > streaming/mjpeg/m1/720p/dwFrameInterval
		# [DJI MODIFIED_BY_DJI_END] add uvc 25fps enum
		# [TC MODIFIED_BY_DJI_END] change uvc to iso

		mkdir -p streaming/mjpeg/m1/1080p
		echo 1920 > streaming/mjpeg/m1/1080p/wWidth
		echo 1080 > streaming/mjpeg/m1/1080p/wHeight
		echo 66355200 > streaming/mjpeg/m1/1080p/dwMinBitRate
		echo 995328000 > streaming/mjpeg/m1/1080p/dwMaxBitRate
		echo 4147200 > streaming/mjpeg/m1/1080p/dwMaxVideoFrameBufferSize
		echo 333333 > streaming/mjpeg/m1/1080p/dwDefaultFrameInterval
		# [TC MODIFIED_BY_DJI_START] change uvc to iso
		# [DJI MODIFIED_BY_DJI_START] add uvc 25fps enum
		echo -e "333333\n400000\n" > streaming/mjpeg/m1/1080p/dwFrameInterval
		# [DJI MODIFIED_BY_DJI_END] add uvc 25fps enum

		# mkdir -p streaming/mjpeg/m/360p
		# echo 640 > streaming/mjpeg/m/360p/wWidth
		# echo 360 > streaming/mjpeg/m/360p/wHeight
		# echo 460800   > streaming/mjpeg/m/360p/dwMaxVideoFrameBufferSize
		# echo 18432000  > streaming/mjpeg/m/360p/dwMinBitRate
		# echo 55296000 > streaming/mjpeg/m/360p/dwMaxBitRate
		# echo -e "166666\n333333\n666666\n1000000\n5000000\n" > streaming/mjpeg/m/360p/dwFrameInterval
		# echo 333333 > streaming/mjpeg/m/360p/dwDefaultFrameInterval
		# [TC MODIFIED_BY_DJI_END] change uvc to iso

		mkdir -p streaming/mjpeg/m/720p
		echo 1280 > streaming/mjpeg/m/720p/wWidth
		echo 720 > streaming/mjpeg/m/720p/wHeight
		echo 32000000 > streaming/mjpeg/m/720p/dwMinBitRate
		echo 96000000 > streaming/mjpeg/m/720p/dwMaxBitRate
		echo 1843200 > streaming/mjpeg/m/720p/dwMaxVideoFrameBufferSize
		echo 333333 > streaming/mjpeg/m/720p/dwDefaultFrameInterval
		# [TC MODIFIED_BY_DJI_START] change uvc to iso
		# [DJI MODIFIED_BY_DJI_START] add uvc 25fps enum
		echo -e "333333\n400000\n" > streaming/mjpeg/m/720p/dwFrameInterval
		# [DJI MODIFIED_BY_DJI_END] add uvc 25fps enum
		# [TC MODIFIED_BY_DJI_END] change uvc to iso

		mkdir -p streaming/mjpeg/m/1080p
		echo 1920 > streaming/mjpeg/m/1080p/wWidth
		echo 1080 > streaming/mjpeg/m/1080p/wHeight
		echo 66355200 > streaming/mjpeg/m/1080p/dwMinBitRate
		echo 995328000 > streaming/mjpeg/m/1080p/dwMaxBitRate
		echo 4147200 > streaming/mjpeg/m/1080p/dwMaxVideoFrameBufferSize
		echo 333333 > streaming/mjpeg/m/1080p/dwDefaultFrameInterval
		# [TC MODIFIED_BY_DJI_START] change uvc to iso
		# [DJI MODIFIED_BY_DJI_START] add uvc 25fps enum
		echo -e "333333\n400000\n" > streaming/mjpeg/m/1080p/dwFrameInterval
		# [DJI MODIFIED_BY_DJI_END] add uvc 25fps enum

		# mkdir -p streaming/mjpeg/m/1440p
		# echo 2560 > streaming/mjpeg/m/1440p/wWidth
		# echo 1440 > streaming/mjpeg/m/1440p/wHeight
		# echo 117964800 > streaming/mjpeg/m/1440p/dwMinBitRate
		# echo 1769472000 > streaming/mjpeg/m/1440p/dwMaxBitRate
		# echo 7372800 > streaming/mjpeg/m/1440p/dwMaxVideoFrameBufferSize
		# echo 333333 > streaming/mjpeg/m/1440p/dwDefaultFrameInterval
		# echo -e "166666\n333333\n" > streaming/mjpeg/m/1440p/dwFrameInterval

		# mkdir -p streaming/mjpeg/m/2160p
		# echo 3840 > streaming/mjpeg/m/2160p/wWidth
		# echo 2160 > streaming/mjpeg/m/2160p/wHeight
		# echo 265420800 > streaming/mjpeg/m/2160p/dwMinBitRate
		# echo 3981312000 > streaming/mjpeg/m/2160p/dwMaxBitRate
		# echo 16588800 > streaming/mjpeg/m/2160p/dwMaxVideoFrameBufferSize
		# echo 333333 > streaming/mjpeg/m/2160p/dwDefaultFrameInterval
		# echo -e "166666\n333333\n666666\n1000000\n5000000\n" > streaming/mjpeg/m/2160p/dwFrameInterval
		# [TC MODIFIED_BY_DJI_END] change uvc to iso

		${LOCAL_ECHO} 0x04 > /sys/kernel/config/usb_gadget/g1/functions/uvc.0/streaming/mjpeg/m/bmaControls
		${LOCAL_ECHO} 0x04 > /sys/kernel/config/usb_gadget/g1/functions/uvc.0/streaming/mjpeg/m1/bmaControls

		# [TC MODIFIED_BY_DJI_START] uvc add support h264
		#720p
		mkdir -p streaming/framebased/f/1280_720
		echo 1280 > streaming/framebased/f/1280_720/wWidth
		echo 720 > streaming/framebased/f/1280_720/wHeight
		echo 18432000 > streaming/framebased/f/1280_720/dwMinBitRate
		echo 248832000 > streaming/framebased/f/1280_720/dwMaxBitRate
		echo 1843200 > streaming/framebased/f/1280_720/dwMaxVideoFrameBufferSize
		echo 333333 > streaming/framebased/f/1280_720/dwDefaultFrameInterval
		# [DJI MODIFIED_BY_DJI_START] add uvc 25fps enum
		echo -e "333333\n400000\n" > streaming/framebased/f/1280_720/dwFrameInterval
		# [DJI MODIFIED_BY_DJI_END] add uvc 25fps enum

		mkdir -p streaming/framebased/f1/1280_720
		echo 1280 > streaming/framebased/f1/1280_720/wWidth
		echo 720 > streaming/framebased/f1/1280_720/wHeight
		echo 18432000 > streaming/framebased/f1/1280_720/dwMinBitRate
		echo 248832000 > streaming/framebased/f1/1280_720/dwMaxBitRate
		echo 1843200 > streaming/framebased/f1/1280_720/dwMaxVideoFrameBufferSize
		echo 333333 > streaming/framebased/f1/1280_720/dwDefaultFrameInterval
		# [DJI MODIFIED_BY_DJI_START] add uvc 25fps enum
		echo -e "333333\n400000\n" > streaming/framebased/f1/1280_720/dwFrameInterval
		# [DJI MODIFIED_BY_DJI_END] add uvc 25fps enum

		#1080p
		mkdir -p streaming/framebased/f/1920_1080
		echo 1920 > streaming/framebased/f/1920_1080/wWidth
		echo 1080 > streaming/framebased/f/1920_1080/wHeight
		echo 18432000 > streaming/framebased/f/1920_1080/dwMinBitRate
		echo 559872000 > streaming/framebased/f/1920_1080/dwMaxBitRate
		echo 4147200 > streaming/framebased/f/1920_1080/dwMaxVideoFrameBufferSize
		echo 333333 > streaming/framebased/f/1920_1080/dwDefaultFrameInterval
		# [DJI MODIFIED_BY_DJI_START] add uvc 25fps enum
		echo -e "333333\n400000\n" > streaming/framebased/f/1920_1080/dwFrameInterval
		# [DJI MODIFIED_BY_DJI_END] add uvc 25fps enum

		mkdir -p streaming/framebased/f1/1920_1080
		echo 1920 > streaming/framebased/f1/1920_1080/wWidth
		echo 1080 > streaming/framebased/f1/1920_1080/wHeight
		echo 18432000 > streaming/framebased/f1/1920_1080/dwMinBitRate
		echo 559872000 > streaming/framebased/f1/1920_1080/dwMaxBitRate
		echo 4147200 > streaming/framebased/f1/1920_1080/dwMaxVideoFrameBufferSize
		echo 333333 > streaming/framebased/f1/1920_1080/dwDefaultFrameInterval
		# [DJI MODIFIED_BY_DJI_START] add uvc 25fps enum
		echo -e "333333\n400000\n" > streaming/framebased/f1/1920_1080/dwFrameInterval
		# [DJI MODIFIED_BY_DJI_END] add uvc 25fps enum
		# [TC MODIFIED_BY_DJI_END] uvc add support h264

		mkdir streaming/header/h
		mkdir streaming/header/h1
		# [TC MODIFIED_BY_DJI_START] change uvc to iso
		# ln -s streaming/uncompressed/u1 streaming/header/h1
		# [TC MODIFIED_BY_DJI_END] change uvc to iso
		# [TC MODIFIED_BY_DJI_START] uvc add support h264
		ln -s streaming/mjpeg/m1 streaming/header/h1
		ln -s streaming/framebased/f1 streaming/header/h1
		# [TC MODIFIED_BY_DJI_END] uvc add support h264

		# [TC MODIFIED_BY_DJI_START] change uvc to iso
		# ln -s streaming/uncompressed/u streaming/header/h
		# [TC MODIFIED_BY_DJI_END] change uvc to iso

		ln -s streaming/mjpeg/m streaming/header/h
		# [TC MODIFIED_BY_DJI_START] uvc add support h264
		ln -s streaming/framebased/f streaming/header/h
		# [TC MODIFIED_BY_DJI_END] uvc add support h264
		ln -s streaming/header/h1 streaming/class/fs/
		ln -s streaming/header/h1 streaming/class/hs/
		# [TC MODIFIED_BY_DJI_START] uvc add support h264
		ln -s streaming/header/h streaming/class/hs/
		# [TC MODIFIED_BY_DJI_END] uvc add support h264
		ln -s streaming/header/h streaming/class/ss/
		cd /
	fi
}

init_uac() {
	# [DJI MODIFIED_BY_DJI_START] set uac name
	#
	# Initialize UAC conifguration.
	#
	if [ -d /sys/kernel/config/usb_gadget/g1/functions/uac2.0 ]; then
		cd /sys/kernel/config/usb_gadget/g1/functions/uac2.0
		echo "Osmo360" > function_name
		echo 0 > c_chmask
		cd /
	fi
	# [DJI MODIFIED_BY_DJI_END] set uac name
}