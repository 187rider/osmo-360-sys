#! /bin/bash

# OQ101 color sensor link test script
# updated data: 2023-09-27

as7341_link_test
if [ $? == 0 ]; then
    echo "as7341 link test success"
else
    echo "as7341 link test failed"
    exit 1
fi
exit 0
