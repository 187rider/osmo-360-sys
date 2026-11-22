# #!/system/bin/sh
#
# this file including a function that trans the text to
# amt v1 data.
#
# Author:
# Date:     2019.8
# version:  1.0
# History:
#           1.0 2019.8 Original version
#

data_to_trans=$1
task_id=$2
timeout=$3
text_length=${#data_to_trans}

script_name_length=512
script_name_length_length=4
script_id=4
script_timeout=4
script_para_length=4

text_to_hex_asc() {
    text=$data_to_trans

    i=0
    while [ i -lt $text_length ]; do
        text_temp1=$(busybox printf %d \'${text:$i:$i+1})
        text_temp2=$(busybox printf %x $text_temp1)
        text_asc=${text_asc}${text_temp2}
        let i+=1
    done
    echo $text_asc
}

trail_by_zero() {
    # number of 0 to trail
    let trail_length=script_name_length-text_length
    let trail_length=trail_length*2
    echo $(text_to_hex_asc)$(busybox printf %0${trail_length}d)
}

trail_by_script_length() {
    echo $(trail_by_zero)$(busybox printf %02x $text_length)000000
}

trail_by_task_id() {
    echo $(trail_by_script_length)${task_id}
}

trail_by_timeout() {
    decimal_num=$timeout
    hex_num=$(busybox printf %08x $decimal_num)

    hex1=${hex_num:6:2}
    hex2=${hex_num:4:2}
    hex3=${hex_num:2:2}
    hex4=${hex_num:0:2}

    echo $(trail_by_task_id)$hex1$hex2$hex3$hex4
}

trail_by_paras_length() {
    echo $(trail_by_timeout)00
}

trail_by_paras() {
    echo $(trail_by_paras_length)
}

text_to_amt_v1() {
    trail_by_paras
}

text_to_amt_v1