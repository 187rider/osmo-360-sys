#!/bin/sh -e

if [ -z $1 ]
then
    echo "Should input root path"
else
    MOUNT_ROOT=$1
    echo "root path ${MOUNT_ROOT}"
fi

if [ -z $2 ]
then
    echo "Should input current round number"
else
    ROUND=$2
    echo "current round number ${ROUND}"
fi

TEST_ROOT="${MOUNT_ROOT}/fname_mgr_test_dir"
TEST_DIR="fname_mgr_test_dir/DCIM/DJI_202103241201_$ROUND"

FAKE_MP4_FILE_CONTENT="Fake mp4 file only for test"
FAKE_JPG_FILE_CONTENT="Fake jpg file only for test"

# test_hal_storage -c "0 volume detach_pc"

sleep 2
echo $MOUNT_ROOT

cd $MOUNT_ROOT
if [ $? -ne 0 ]
then
    echo "invalid input root path"
    exit 1
fi

rm -rf $TEST_ROOT
mkdir -p $TEST_DIR

cd $TEST_DIR
echo "$TEST_DIR"

for j in $(seq -f "%04.f" 1 $((ROUND*250)))
do
    echo ${FAKE_MP4_FILE_CONTENT} > "DJI_20210324${j}59_${j}_T_customfilename${j}.mp4"
done

for j in $(seq -f "%04.f" $((ROUND*250+1)) $((ROUND*500)))
do
    echo ${FAKE_JPG_FILE_CONTENT} > "DJI_20210324${j}59_${j}_T_customfilename${j}.jpg"
done

# TODO: Add SUPER dir and files
