#!/bin/bash

# 最大重试次数
max_retries=10
# 当前重试次数
retry_count=0
# 等待时间（秒）
wait_time=2

# 检查 boot_slot
boot_slot=$(/sbin/abctl --boot_slot)

# 如果 boot_slot 是 _a、_b 或 _c，则进行后续操作
if [[ "$boot_slot" == "_a" || "$boot_slot" == "_b" || "$boot_slot" == "_c" ]]; then
    while [ $retry_count -lt $max_retries ]; do
        # 执行 abctl --set_success
        /sbin/abctl --set_success
        # 获取返回值
        result=$?

        # 如果返回值是 0，成功，退出循环
        if [ $result -eq 0 ]; then
            echo "<3>abctl --set_success succeeded." > /dev/kmsg
            exit 0
        else
            # 返回值非 0，失败，等待并重试
            echo "<3>abctl --set_success failed: $result, retry in $wait_time seconds..." > /dev/kmsg
            sleep $wait_time
            retry_count=$((retry_count + 1))
        fi
    done

    # 如果达到最大重试次数，输出失败信息
    echo "<3>abctl --set_success failed after $max_retries attempts." > /dev/kmsg
    exit 1
else
    echo "<3>Boot slot is not _a, _b, or _c, no abctl action taken." > /dev/kmsg
    exit 0
fi
