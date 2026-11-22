DEV_NAME="gpio-keys"
event_num=0
input_num=10
period_time=0.1
if [ $# != 0  ]; then
    period_time=$1
fi
# get key/touch input event number
while [ $event_num -lt $input_num ]
do
    dev_name=`cat /sys/class/input/event$event_num/device/name`
    if [ "$dev_name" == "$DEV_NAME" ]; then
        echo "get $DEV_NAME event_num=$event_num"
        break;
    fi
    let event_num++
done
function button_press_and_release()
{
    # simulate the user pressing the button
    sendevent /dev/input/event$event_num 1 357 1
    sendevent /dev/input/event$event_num 0 0 0
    sleep $1
    # simulate the user release button
    sendevent /dev/input/event$event_num 1 357 0
    sendevent /dev/input/event$event_num 0 0 0
}
button_press_and_release $period_time
