function app_led_red_on()
{
    simulate_device -n ColorTest 2 255 0 0
    echo red_on > ${led_status_to_update}
    sync
}

function app_led_green_on()
{
    simulate_device -n ColorTest 2 0 255 0
    echo green_on > ${led_status_to_update}
    sync
}

function app_led_red_blink()
{
    simulate_device -n ColorTest 2 0 255 255
    echo red_blink > ${led_status_to_update}
    sync
}

function app_led_green_blink()
{
    # green_blink is yellow, becaus simulate_device do not support blink
    simulate_device -n ColorTest 2 255 255 0
    echo green_blink > ${led_status_to_update}
    sync
}
