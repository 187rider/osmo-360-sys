#!/bin/sh

#
# LOCK
#

lock_file=/data/dji/amt/lock

aging_test_lock_init()
{
    if [ -f $lock_file ]; then
        echo "$BASKPID remove lock file before aging test"
        rm -rf $lock_file
    fi
}

aging_test_lock()
{
    sync
    while [ -f $lock_file ]; do
        echo "$BASHPID waiting for lock release..."
        sleep 2
        sync
    done

    echo "$BASHPID get aging test lock"
    touch $lock_file
    sync
}

aging_test_unlock()
{
    sync
    rm -rf $lock_file
    echo "$BASHPID release aging test lock"
}
