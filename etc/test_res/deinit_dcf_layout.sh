#!/bin/sh -e

MOUNT_ROOT=$1
echo "test dir is $1"

TEST_ROOT="${MOUNT_ROOT}/fname_mgr_test_dir"

cd $MOUNT_ROOT

rm -rf $TEST_ROOT

TEST_ROOT="${MOUNT_ROOT}/fname_mgr_test_dir_loop_rec"

rm -rf $TEST_ROOT

TEST_ROOT="${MOUNT_ROOT}/mount*"

rm -rf $TEST_ROOT