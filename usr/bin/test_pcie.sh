#!/bin/sh
# test if wifi pcie is ok

vendor_id="14e4"
product_id="4362"

pcie=`lspci  | grep $vendor_id:$product_id`
if [ "${pcie}" == "" ];then
    echo "test pcie failed"
	exit 1
fi

echo "test pcie success"


