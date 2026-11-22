# check led about oq101

if [ "$#" -eq 0 ]; then
    echo "param is null, test failed, param: red, green or yellow"
    exit 1
fi

color=$1
echo "param:"$1
if [ $1 = "red" ]; then
    echo 0 > /sys/class/leds/red/brightness
    echo 0 > /sys/class/leds/green/brightness
    echo 255 > /sys/class/leds/red/brightness
    echo "set param ok, please check red led"
    exit 0
elif [ $1 = "green" ]; then
    echo 0 > /sys/class/leds/red/brightness
    echo 0 > /sys/class/leds/green/brightness
    echo 255 > /sys/class/leds/green/brightness
    echo "set param ok, please check green led"
    exit 0
elif [ $1 = "yellow" ]; then
    echo 0 > /sys/class/leds/red/brightness
    echo 0 > /sys/class/leds/green/brightness
    echo 255 > /sys/class/leds/green/brightness
    echo 255 > /sys/class/leds/red/brightness
    echo "set param ok, please check yellow led"
    exit 0
else
    echo "param error, test failed, param: red, green or yellow"
    exit 1
fi

