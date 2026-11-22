#!/system/bin/sh
. aging_test_configure.sh

#
# LED
#

red_led_name="red"
green_led_name="green"


led_ctrl_init()
{
    if [ -f ${led_status_file} ]; then
        rm -rf ${led_status_file}
    fi
    if [ -f ${led_status_to_update} ]; then
        rm -rf ${led_status_to_update}
    fi
    sync
    touch ${led_status_file}
    touch ${led_status_to_update}
    sync
    sleep 15
    echo "led_ctrl_init done"
}

#######################################action#################################################
led_green_blink()
{
    echo "led_green_blink enter"
    echo green_blink > $led_status_file
    while true; do
        local new_status=$(cat ${led_status_to_update})
        local old_status=$(cat ${led_status_file})
        if [ "x${new_status}" != "x${old_status}" ]; then
            break
        fi
        simulate_device -n ColorTest 2 255 255 0
        sleep 0.5
    done
    echo "led_green_blink done"
}

led_green_on()
{
    echo "led_green_on enter"
    simulate_device -n ColorTest 2 0 255 0
    echo "led_green_on done"
    echo green_on > $led_status_file
}

led_red_blink()
{
    echo "led_red_blink enter"
    echo red_blink > $led_status_file
    while true; do
        local new_status=$(cat ${led_status_to_update})
        local old_status=$(cat ${led_status_file})
        if [ "x${new_status}" != "x${old_status}" ]; then
            break
        fi
        simulate_device -n ColorTest 2 0 255 255
        sleep 0.5
    done
    echo "led_red_blink done"
}

function led_red_on()
{
    echo "led_red_on enter"
    simulate_device -n ColorTest 2 255 0 0
    echo "led_red_on done"
    echo red_on > $led_status_file
}

led_ctrl_init
while true; do
    if [ -f ${end_of_aging_test} ]; then
        echo "aging test is over, LED control task is exiting"
        exit 0
    fi
    local new_status=$(cat ${led_status_to_update})
    local old_status=$(cat ${led_status_file})
    if [ "x${new_status}" != "x${old_status}" ]; then
        echo new:${new_status}
        echo old:${old_status}

        case ${new_status} in
        red_on)
            led_red_on
            ;;
        green_on)
            led_green_on
            ;;
        red_blink)
            led_red_blink
            ;;
        green_blink)
            led_green_blink
            ;;
        *)
            echo "Invalid new_status=${new_status}"
            continue
            ;;
        esac
        echo ${new_status} > ${led_status_file}
    fi
    sleep 0.5
done
