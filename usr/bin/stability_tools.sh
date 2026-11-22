#!/bin/sh

# do not set / (root_file) to rw, that make diff-upgrade failed 
# mount -o rw,remount /

# NR_FILES=10
# KPANIC_CONSOLE_FILE="/data/dji/log/kpanic_console"
# DONTPANIC_CONSOLE_FILE="/data/dontpanic/kpanic_console"
# $4 is 0 or 1.if 1,will tar file
# process_kpanic $NR_FILES $KPANIC_CONSOLE_FILE $DONTPANIC_CONSOLE_FILE $IS_TAR
function process_kpanic() {
	COUNTER=$1
	KPANIC_FILE=$2
	DONTPANIC_FILE=$3
	IS_TAR=$4
	DOT="."
	SUFFIX=""

	if [ $IS_TAR -gt 0 ];then
		SUFFIX=".tar.gz"
	fi
	if [ -f "$DONTPANIC_FILE" ];then

		while [ $COUNTER -gt 0 ]
		do
		    OLD_FILE=$KPANIC_FILE$DOT$COUNTER$SUFFIX
		    if [ -f "$OLD_FILE" ];then
			NEW_FILE=$KPANIC_FILE$DOT$(($COUNTER+1))$SUFFIX
			echo "rename $OLD_FILE to $NEW_FILE"
			mv $OLD_FILE $NEW_FILE
		    fi

		let COUNTER=$COUNTER-1
		#echo $COUNTER
		done

		OLD_FILE=$KPANIC_FILE$SUFFIX
		if [ -f "$OLD_FILE" ];then
			NEW_FILE=$KPANIC_FILE".1"$SUFFIX
			echo "rename $OLD_FILE to $NEW_FILE"
			mv $OLD_FILE $NEW_FILE
		fi

		echo "move $DONTPANIC_FILE to $OLD_FILE"  >> /dev/kmsg
		if [ $IS_TAR -gt 0 ];then
			busybox tar -zcf $OLD_FILE $DONTPANIC_FILE
			rm -rf $DONTPANIC_FILE
		else
			mv $DONTPANIC_FILE $OLD_FILE
		fi
	fi
}

mkdir -p /blackbox/system/coredump
chmod o+rwx /blackbox/system/coredump

echo "/blackbox/system/coredump/core.%n.%i.%tS" > /proc/sys/kernel/core_pattern 

root_path=/blackbox/system/coredump/info
if [ ! -e $root_path ]; then
    mkdir -p $root_path
    chmod o+rwx $root_path
    cp -f /firmware/verinfo/ver_info.txt $root_path/version.info
    echo "qcs8550_oq101" > $root_path/product.info
fi

echo "1" > /proc/sys/kernel/core_uses_pid

echo "1" > /proc/sys/kernel/softlockup_panic
echo "1" > /proc/sys/kernel/panic_on_rcu_stall

if [ ! -d "/blackbox/system/memleak" ];then
    mkdir -p /blackbox/system/memleak
fi

NR_FILES=2
MEMLEAK_FILE="/blackbox/system/memleak_compressed"
MEMLEAK_TEMP_FILE="/blackbox/system/memleak/temp"
memleak_count=`busybox ls /blackbox/system/memleak/stack* | busybox wc -l`
if [ $memleak_count -ne 0 ]; then
    busybox tar -cvzf /blackbox/system/memleak/temp /blackbox/system/memleak/*
    process_kpanic $NR_FILES $MEMLEAK_FILE $MEMLEAK_TEMP_FILE 0
    rm -rf /blackbox/system/memleak/*
fi

if [ ! -d "/blackbox/system/kevent" ];then
    mkdir -p /blackbox/system/kevent
fi
if [ ! -d "/blackbox/system/kpanic" ];then
    mkdir -p /blackbox/system/kpanic
fi
tombstone_trace_file="/blackbox/system/tombstone_trace"
tombstone_trace_file_temp="/blackbox/system/tombstone_trace_temp"
if [ -f $tombstone_trace_file_temp ];then
	rm $tombstone_trace_file_temp
fi
extract_tombstone_key_info()
{
	TOMBSTONE_NUM=$(grep -c "event_type:App_crash" /blackbox/system/kevent.log)
	if [ $TOMBSTONE_NUM -ne 0  ]; then
		LOG_TOMBSTONE_NUM="tombstone_times:"$TOMBSTONE_NUM
		echo "$LOG_TOMBSTONE_NUM" >> $tombstone_trace_file_temp
		grep "event_type:App_crash" /blackbox/system/kevent.log | while read -r line; do
			LOG_THREAD_NAME="crash_thread_name"
			LOG_TASK_NAME="crash_task_name"
			thread=${line#*thread:}
			THREAD_NAME=${thread%%]*}
			echo $LOG_THREAD_NAME":"$THREAD_NAME >> $tombstone_trace_file_temp
			task=${line#*task:}
			TASK_NAME=${task%%]*}
			echo $LOG_TASK_NAME":"$TASK_NAME >> $tombstone_trace_file_temp

			LOG_BACKTRACE="backtrace"
			COUNTER=0
			signal=${line#*signal:}
			signal=${signal%%]*}
			echo "$LOG_BACKTRACE$COUNTER:get_signal_$signal" >> $tombstone_trace_file_temp
			echo "tombstone_trace_end" >> $tombstone_trace_file_temp
		done
		mv $tombstone_trace_file_temp $tombstone_trace_file
	fi
}

NR_FILES=4
KEVENT_FILE="/blackbox/system/kevent/kevent.log"
KEVENT_TEMP_FILE="/blackbox/system/kevent.log"
if [ -f $KEVENT_TEMP_FILE ]; then
	chmod 0640 $KEVENT_TEMP_FILE
	extract_tombstone_key_info
	date >> $KEVENT_TEMP_FILE
	process_kpanic $NR_FILES $KEVENT_FILE $KEVENT_TEMP_FILE 0
fi

kpanic_trace_file="/blackbox/system/kpanic_trace"
kpanic_trace_file_temp="/blackbox/system/kpanic_trace_temp"
if [ -f $kpanic_trace_file_temp  ];then
	rm $kpanic_trace_file_temp
fi
extract_kpanic_console_keyinfo()
{
	filename="/blackbox/system/kpanic_console"

	panic_line=`busybox grep 'Kernel panic - not syncing' $filename`
	if [ -n "$panic_line" ];then
		panic_line_notime=${panic_line#*]}
		common_string=${panic_line_notime%%Kernel*}

		COUNTER=0
		common_str=${common_string}
		LOG_CALL_TRACE="call_trace"
		IFS=$'\n'
		for line in `grep -F "$common_str" $filename | grep -F "+0x"`
		do
			skip_line=`echo $line | grep -E "unwind_backtrace|show_stack|dump_stack|dump_backtrace"`
			if [ -z "$skip_line" ];then
				call_trace=${line#*"$common_str "}
				echo $LOG_CALL_TRACE$COUNTER":"$call_trace >> $kpanic_trace_file_temp
				let COUNTER=$COUNTER+1
			fi
		done
	fi
	panic_reason="pshold"
	panic_reason_line=`busybox grep 'panic_reason:' $filename`
	if [ -n "$panic_reason_line"  ];then
		panic_time_string=${panic_reason_line%%]*}
		panic_run_time=${panic_time_string#*'['}
		echo "panic_run_time:"$panic_run_time >> $kpanic_trace_file_temp
		panic_reason=${panic_reason_line#*panic_reason:}
	fi
	echo "panic_reason:"$panic_reason >> $kpanic_trace_file_temp
	panic_task_line=`busybox grep 'panic_task:' $filename`
	if [ -n "$panic_task_line"  ];then
		panic_task=${panic_task_line#*panic_task:}
		echo "panic_task:"$panic_task >> $kpanic_trace_file_temp
	fi
	echo "kpanic_trace_end" >> $kpanic_trace_file_temp
	mv $kpanic_trace_file_temp $kpanic_trace_file
}
NR_FILES=4
KPANIC_CONSOLE_FILE="/blackbox/system/kpanic/kpanic_console"
DONTPANIC_CONSOLE_FILE="/blackbox/system/kpanic_console"
# process kpanic_console
if [ -f $DONTPANIC_CONSOLE_FILE ];then
    echo "process kpanic_console"
    chmod 0640 $DONTPANIC_CONSOLE_FILE
    date >> $DONTPANIC_CONSOLE_FILE
    extract_kpanic_console_keyinfo
    process_kpanic $NR_FILES $KPANIC_CONSOLE_FILE $DONTPANIC_CONSOLE_FILE 0
fi
