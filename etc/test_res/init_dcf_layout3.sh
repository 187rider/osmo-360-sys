#!/bin/sh -e

if [ -z $1 ]
then
    echo "Should input root path"
else
    MOUNT_ROOT=$1
    echo "root path ${MOUNT_ROOT}"
fi

TEST_ROOT="${MOUNT_ROOT}/fname_mgr_test_dir"
TEST_DIR='fname_mgr_test_dir/DCIM'
DB_DIR='fname_mgr_test_dir/MISC'

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

rm -rf $TEST_ROOT

rm -rf $TEST_DIR
mkdir -p $TEST_DIR
mkdir -p $DB_DIR

cd $TEST_DIR
DIR_END=0
FILE_END=6

# 100MEDIA-103MEDIA, DJI_000{1-9}.MP4, DJI_099{0-9}.JPG
for i in $(seq 0 ${DIR_END})
do
    mkdir "10${i}MEDIA"
    cd "10${i}MEDIA"
    echo "10${i}MEDIA"

    for j in $(seq 1 ${FILE_END})
    do
        touch "DJI_000${j}.MP4"
        #echo "DJI_000${j}.MP4"
    done

    cd ..
done
