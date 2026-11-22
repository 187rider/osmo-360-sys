#! /system/bin/sh

echo "shell param:"
echo "print param:$1 $2 $3 $4"

TEST_DIR1="/mnt/media_rw/emulated/mount1/DCIM"
TEST_DIR2="/mnt/media_rw/emulated/mount2/DCIM"

mkdir -p ${TEST_DIR1}
cd ${TEST_DIR1}
rm -rf ${TEST_DIR1}/*
mkdir ${TEST_DIR1}/$1
touch ${TEST_DIR1}/$1/$2

mkdir -p ${TEST_DIR2}
cd ${TEST_DIR2}
rm -rf ${TEST_DIR2}/*
mkdir ${TEST_DIR2}/$3
touch ${TEST_DIR2}/$3/$4