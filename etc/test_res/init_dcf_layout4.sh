#!/bin/sh -e

if [ -z $1 ]
then
    echo "Should input root path"
else
    MOUNT_ROOT1=$1
    echo "root path ${MOUNT_ROOT1}"
fi

if [ -z $2 ]
then
    echo "Should input root path"
else
    MOUNT_ROOT2=$2
    echo "root path ${MOUNT_ROOT2}"
fi

TEST_ROOT1="${MOUNT_ROOT1}"
TEST_ROOT2="${MOUNT_ROOT2}"

sleep 1
echo $MOUNT_ROOT1
mkdir -p $MOUNT_ROOT1
echo $MOUNT_ROOT2
mkdir -p $MOUNT_ROOT2

