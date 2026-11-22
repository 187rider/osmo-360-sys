#!/bin/sh

rpmbClient smci -p 2
if [ $? -ne 0 ]; then
echo "begin to inject rpmb key"
rpmbClient smci -p 1
exit $?
else
echo "the rpmb key has injected"
exit 0
fi
