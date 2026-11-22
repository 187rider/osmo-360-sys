#! /bin/sh

handle_sigpipe()
{
  echo "collect_log.sh received the SIGPIPE signal" > /dev/kmsg
}
trap handle_sigpipe SIGPIPE

LOG_DIR=$1/
TMP_FOLDER=tmp_floder/
TMP_FOLDER_DIR=$LOG_DIR/$TMP_FOLDER/
FULL_LOG=$2
LAST_NLOG=$3
BUSYBOX=$4

ERROR=1
NO_LOG=2
SUCCESS=3

getLastN()
{
	files=$1
	lastN=$2
	if [ ! $lastN ]
	then
		echo $files
		return
	fi
	files_num=`echo $files | wc -w`
	files_post=""
	idx=0
	discard_num=`expr $files_num - $lastN`
	for i in $files
	do
		if [ $idx -lt $discard_num ]
		then
			let idx+=1
		else
			files_post="$files_post $i"
		fi
	done
	echo "$files_post"
}

# statistics
files_noncompress=`ls $LOG_DIR | grep "^ktop.log.[0-9]*$" | $BUSYBOX sort -n -t '.' -k3`
num_noncompress=`echo $files_noncompress | wc -w`
files_compress=`ls $LOG_DIR | grep "^ktop.log.[0-9]*.tar.gz" | $BUSYBOX sort -n -t '.' -k3`
num_compress=`echo $files_compress | wc -w`

if [ `expr $num_compress + $num_noncompress` == 0 ]
then
	echo $NO_LOG
	exit
fi

if [ ! $LAST_NLOG ]
then
	LAST_NLOG=`expr $num_compress + $num_noncompress`
fi

if [ $LAST_NLOG -gt `expr $num_compress + $num_noncompress` ]
then
	LAST_NLOG=`expr $num_compress + $num_noncompress`
fi

rm $LOG_DIR"/"$FULL_LOG > /dev/null 2>&1
touch $LOG_DIR"/"$FULL_LOG
if [ $LAST_NLOG -lt $num_noncompress ]
then
	files_post=`getLastN "$files_noncompress" $LAST_NLOG`
	for i in $files_post
	do
		busybox nice -19 cat $LOG_DIR"/"$i >> $LOG_DIR"/"$FULL_LOG
	done
else
	mkdir -p $TMP_FOLDER_DIR
	num_need_uncompress=`expr $LAST_NLOG - $num_noncompress`
	files_need_uncompress=`getLastN "$files_compress" $num_need_uncompress`
	for i in $files_need_uncompress
	do
		$BUSYBOX tar -xf $LOG_DIR"/"$i -C $TMP_FOLDER_DIR
	done
	for i in $files_noncompress
	do
		cp $LOG_DIR"/"$i $TMP_FOLDER_DIR
	done
	files_tmp=`ls $TMP_FOLDER_DIR | grep "^ktop.log.[0-9]*$" | $BUSYBOX sort -n -t '.' -k3`
	for i in $files_tmp
	do
		busybox nice -19 cat $TMP_FOLDER_DIR"/"$i >> $LOG_DIR"/"$FULL_LOG
	done
	rm -rf $TMP_FOLDER_DIR
fi
echo $SUCCESS
