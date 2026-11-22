#!/bin/sh

file_max=$(cat /proc/sys/fs/file-max)
echo "fs.file-max=$file_max"

netdev_max_backlog=$(cat /proc/sys/net/core/netdev_max_backlog)
echo "net.core.netdev_max_backlog=$netdev_max_backlog"

optmem_max=$(cat /proc/sys/net/core/optmem_max)
echo "net.core.optmem_max=$optmem_max"

rmem_default=$(cat /proc/sys/net/core/rmem_default)
echo "net.core.rmem_default=$rmem_default"

rmem_max=$(cat /proc/sys/net/core/rmem_max)
echo "net.core.rmem_max=$rmem_max"

wmem_default=$(cat /proc/sys/net/core/wmem_default)
echo "net.core.wmem_default=$wmem_default"

wmem_max=$(cat /proc/sys/net/core/wmem_max)
echo "net.core.wmem_max=$wmem_max"

tcp_mem=$(cat /proc/sys/net/ipv4/tcp_mem)
echo "net.ipv4.tcp_mem=$tcp_mem"

tcp_rmem=$(cat /proc/sys/net/ipv4/tcp_rmem)
echo "net.ipv4.tcp_rmem=$tcp_rmem"

tcp_wmem=$(cat /proc/sys/net/ipv4/tcp_wmem)
echo "net.ipv4.tcp_wmem=$tcp_wmem"

tcp_limit_output_bytes=$(cat /proc/sys/net/ipv4/tcp_limit_output_bytes)
echo "net.ipv4.tcp_limit_output_bytes=$tcp_limit_output_bytes"
