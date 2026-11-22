mount -o rw,remount /
file_path="/system/etc/camera_system_pt_case.conf"
delimiter=":"
testcase=""
while IFS= read -r line; do
  testcase=$testcase+"${line}${delimiter}"
done < "$file_path"
testcase=${testcase//+/}
testcase="${testcase%:}"
dji_camera_system_pt --gtest_filter=$testcase