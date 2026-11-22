#!/bin/bash
echo "start copy imu_cali data to factory_data"
mv "/data/imu_cali.bin" "/factory_data/gimbal/imu_cali.bin"
sync
echo "copy imu_cali data success"
exit 0
