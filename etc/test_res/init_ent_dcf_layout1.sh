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
FAKE_MP4_FILE_CONTENT="Fake mp4 file only for test"
FAKE_JPG_FILE_CONTENT="Fake jpg file only for test"

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

cd $TEST_DIR
DIR_END=3
FILE_END=9

for i in $(seq 1 ${DIR_END})
do
    mkdir "DJI_20210324120${i}_00${i}"
    cd "DJI_20210324120${i}_00${i}"
    echo "DJI_20210324120${i}_00${i}"

    for j in $(seq 1 ${FILE_END})
    do
        echo ${FAKE_MP4_FILE_CONTENT} > "DJI_20210324130${j}59_000${j}_T.mp4"
        echo ${FAKE_MP4_FILE_CONTENT} > "DJI_20210324130${j}59_000${j}_Z.mp4"
        echo ${FAKE_MP4_FILE_CONTENT} > "DJI_20210324130${j}59_000${j}_W.MP4"
        echo ${FAKE_MP4_FILE_CONTENT} > "DJI_20210324130${j}59_000${j}_S.MP4"
    done

    for j in $(seq 10 19)
    do
        echo ${FAKE_JPG_FILE_CONTENT} > "DJI_2021032413${j}59_00${j}_T.jpg"
        echo ${FAKE_JPG_FILE_CONTENT} > "DJI_2021032413${j}59_00${j}_Z.jpg"
        echo ${FAKE_JPG_FILE_CONTENT} > "DJI_2021032413${j}59_00${j}_W.JPG"
        echo ${FAKE_JPG_FILE_CONTENT} > "DJI_2021032413${j}59_00${j}_S.JPG"
    done

    # TODO: Add SUPER dir and files

    cd ..
done

# Add Pano dir and files
TEST_PANO="DJI_20210324120$((DIR_END + 1))_00$((DIR_END + 1))"
TEST_PANO_SUB="PANORAMA/00$((DIR_END + 1))_0001"
TEST_PANO_NAIL="MISC/THM/PANORAMA/00$((DIR_END + 1))_0001"

echo  $TEST_PANO
mkdir $TEST_PANO
cd $TEST_PANO
touch DJI_20210324140001_0001_D.html
cd ..

echo  $TEST_PANO_SUB
mkdir -p $TEST_PANO_SUB
cd $TEST_PANO_SUB

for i in $(seq 0 ${FILE_END})
do
    echo ${FAKE_JPG_FILE_CONTENT} > "PANO_000${i}.JPG"
    echo ${FAKE_JPG_FILE_CONTENT} > "PANO_001${i}.JPG"
    echo ${FAKE_JPG_FILE_CONTENT} > "PANO_002${i}.JPG"
done
rm PANO_0000.JPG

cd ../../../
echo  $TEST_PANO_NAIL
mkdir -p $TEST_PANO_NAIL
cd $TEST_PANO_NAIL
for i in $(seq 0 ${FILE_END})
do
    echo ${FAKE_NAIL_FILE_CONTENT} > "PANO_000${i}.SCR"
    echo ${FAKE_NAIL_FILE_CONTENT} > "PANO_000${i}.THM"
    echo ${FAKE_NAIL_FILE_CONTENT} > "PANO_001${i}.SCR"
    echo ${FAKE_NAIL_FILE_CONTENT} > "PANO_001${i}.THM"
    echo ${FAKE_NAIL_FILE_CONTENT} > "PANO_002${i}.SCR"
    echo ${FAKE_NAIL_FILE_CONTENT} > "PANO_002${i}.THM"
done
rm PANO_0000.SCR
rm PANO_0000.THM

cd ../../../../DCIM
# Add Pano end

for i in $(seq 1 ${DIR_END})
do
    mkdir "DJI_20210324140${i}_99${i}"
    cd "DJI_20210324140${i}_99${i}"
    echo "DJI_20210324140${i}_99${i}"

    for j in $(seq 1 ${FILE_END})
    do
        echo ${FAKE_MP4_FILE_CONTENT} > "DJI_20210324140${j}59_998${j}_T.mp4"
        echo ${FAKE_MP4_FILE_CONTENT} > "DJI_20210324140${j}59_998${j}_Z.mp4"
        echo ${FAKE_MP4_FILE_CONTENT} > "DJI_20210324140${j}59_998${j}_W.MP4"
        echo ${FAKE_MP4_FILE_CONTENT} > "DJI_20210324140${j}59_998${j}_S.MP4"
    done

    for j in $(seq 1 ${FILE_END})
    do
        echo ${FAKE_JPG_FILE_CONTENT} > "DJI_20210324140${j}59_999${j}_T.jpg"
        echo ${FAKE_JPG_FILE_CONTENT} > "DJI_20210324140${j}59_999${j}_Z.jpg"
        echo ${FAKE_JPG_FILE_CONTENT} > "DJI_20210324140${j}59_999${j}_W.JPG"
        echo ${FAKE_JPG_FILE_CONTENT} > "DJI_20210324140${j}59_999${j}_S.JPG"
    done
    cd ..
done
