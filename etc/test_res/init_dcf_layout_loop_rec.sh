#!/bin/sh -e

if [ -z $1 ]
then
    echo "Should input root path"
else
    MOUNT_ROOT=$1
    echo "root path ${MOUNT_ROOT}"
fi

TEST_DIR='fname_mgr_test_dir_loop_rec/DCIM'

# test_hal_storage -c "0 volume detach_pc"

sleep 2
echo $MOUNT_ROOT
mkdir -p $MOUNT_ROOT

cd $MOUNT_ROOT
if [ $? -ne 0 ]
then
    echo "invalid input root path"
    exit 1
fi

rm -rf $TEST_DIR

mkdir -p $TEST_DIR
cd $TEST_DIR

# 105MEDIA, DJI_0005_00{1-5}.MP4
mkdir "105MEDIA"
cd "105MEDIA"
echo "105MEDIA"
    touch -d "2021-01-01 00:01:01" "DJI_0005_001.MP4"
    echo "    DJI_0005_001.MP4"
    touch -d "2021-01-01 00:01:02" "DJI_0005_002.MP4"
    echo "    DJI_0005_002.MP4"
    touch -d "2021-01-01 00:01:03" "DJI_0005_003.MP4"
    echo "    DJI_0005_003.MP4"
    touch -d "2021-01-01 00:01:04" "DJI_0005_004.MP4"
    echo "    DJI_0005_004.MP4"
    touch -d "2021-01-01 00:01:05" "DJI_0005_005.MP4"
    echo "    DJI_0005_005.MP4"
cd ..

# 106MEDIA, DJI_0006_996.MP4, DJI_0006_997.MP4, DJI_0006_998.MP4, DJI_0006_999.MP4, DJI_0006_001.MP4
mkdir "106MEDIA"
cd "106MEDIA"
echo "106MEDIA"
    touch -d "2021-01-01 00:02:01" "DJI_0006_996.MP4"
    echo "    DJI_0006_996.MP4"
    touch -d "2021-01-01 00:02:02" "DJI_0006_997.MP4"
    echo "    DJI_0006_997.MP4"
    touch -d "2021-01-01 00:02:03" "DJI_0006_998.MP4"
    echo "    DJI_0006_998.MP4"
    touch -d "2021-01-01 00:02:04" "DJI_0006_999.MP4"
    echo "    DJI_0006_999.MP4"
    echo "    ::DJI_0006_001.MP4 will replace DJI_0006_995.MP4"
    touch -d "2021-01-01 00:02:05" "DJI_0006_001.MP4"
    echo "    DJI_0006_001.MP4"
cd ..

# 107MEDIA, DJI_0007_001.MP4, DJI_0007_002.MP4, DJI_0007_003.MP4,        , DJI_0007_001.MP5
mkdir "107MEDIA"
cd "107MEDIA"
echo "107MEDIA"
    touch -d "2021-01-01 00:03:01" "DJI_0007_001.MP4"
    echo "    DJI_0007_001.MP4"
    touch -d "2021-01-01 00:03:02" "DJI_0007_002.MP4"
    echo "    DJI_0007_002.MP4"
    touch -d "2021-01-01 00:03:03" "DJI_0007_003.MP4"
    echo "    DJI_0007_003.MP4"
    echo "    ::no DJI_0007_004.MP4"
    touch -d "2021-01-01 00:03:05" "DJI_0007_005.MP4"
    echo "    DJI_0007_005.MP4"
cd ..
