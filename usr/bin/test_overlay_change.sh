#!/bin/bash

filePath="blackbox/etc_dir.txt"
touch blackbox/tempfile
tempFile=blackbox/tempfile
searchString="Class_Gold"
etc_expected_md5="647bd66a73f883ed60b585003904bd7e"
data_expected_md5="38eab3016ba68742aecbd4087013b2e3"
cache_expected_md5="2c31cf4c7ac527415f1853f6fa836675"

mkdir /blackbox/sda7
mkdir /blackbox/sda8
mount dev/sda7 /blackbox/sda7
ls -Rb /blackbox/sda7/etc > blackbox/etc_dir.txt
ls -R /blackbox/sda7/data > blackbox/data_dir.txt
ls -R /blackbox/sda7/cache > blackbox/cache_dir.txt

# 清空临时文件
> "$tempFile"

# 逐行读取原始文件并检查是否包含目标字符串
while IFS= read -r line; do
    if [[ $line == *"$searchString"* ]]; then
        echo "Found line with \"$searchString\" string: $line"
    else
        echo "$line" >> "$tempFile"
    fi
done < "$filePath"

# 将临时文件替换原始文件
mv "$tempFile" "$filePath"

etc_file_md5=$(md5sum blackbox/etc_dir.txt | cut -c 1-32)
echo "$etc_file_md5"
data_file_md5=$(md5sum blackbox/data_dir.txt | cut -c 1-32)
echo "$data_file_md5"
cache_file_md5=$(md5sum blackbox/cache_dir.txt | cut -c 1-32)
echo "$cache_file_md5"

# 比较 etc MD5 值
if [ "$etc_file_md5" = "$etc_expected_md5" ]; then
    echo "etc dir check success"
else
    echo "etc dir check fail"
fi

# 比较 data MD5 值
if [ "$data_file_md5" = "$data_expected_md5" ]; then
    echo "data dir check success"
else
    echo "data dir check fail"
fi

# 比较 cache MD5 值
if [ "$cache_file_md5" = "$cache_expected_md5" ]; then
    echo "cache dir check success"
else
    echo "cache dir check fail"
fi
