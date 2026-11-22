#!/bin/sh
while [ 1 ]; do if [ -f "/sys/kernel/snd_card/card_state" ]; then chmod 0666 /sys/kernel/snd_card/card_state; break; else sleep 0.05; fi done

/usr/bin/pulseaudio --system --daemonize=no -vvvv
