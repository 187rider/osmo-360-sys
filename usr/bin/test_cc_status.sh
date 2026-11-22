#!/bin/sh
# check cc status
cd /sys/kernel/debug/regmap/0-07/
if [ $? -ne 0 ]; then
    echo "cd patch failed"
    exit 1
fi
echo 0x2B00 > address
echo 0x10 > count

reg_data=`cat /sys/kernel/debug/regmap/0-07/data`
if [ $? -ne 0 ]; then
    echo "get data failed"
    exit 1
fi

echo $reg_data
hex_value=`echo $(echo "$reg_data" | awk -F'2b09: ' '{print $2}' | awk '{print $1}')`
decimal_val=$((16#${hex_value}))
echo $decimal_val
echo "reg val(2b09): $hex_value(hex) $decimal_val(dec)"
cc1=$(( (decimal_val >> 6) & 0x01))
cc2=$(( (decimal_val >> 7) & 0x01))
echo "cc1:${cc1}, cc2:${cc2}"
if [[ $cc1 -eq 1 ]] && [[ $cc2 -eq 0 ]]; then
    echo "ADAPTER_CC1_ATTACH"
elif [[ $cc1 -eq 0 ]] && [[ $cc2 -eq 1 ]]; then
    echo "ADAPTER_CC2_ATTACH"
else
    echo "ADAPTER_CC_DETACH"
fi

exit 0
