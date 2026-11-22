#!/bin/bash
test_res=$(ssc_drva_test -sensor=eis -duration=1 -sample_rate=8000)
echo $test_res
test_fir=${test_res#*total_samples=}
test_sec=${test_fir:0:4}
let res=$test_sec
echo $res
let threshold=900
if (($res > $threshold));then
 echo "imu test success"
 exit 0
else
 echo "imu test fail"
 fi
