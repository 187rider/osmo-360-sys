#!/bin/sh
udevadm trigger --type=subsystems --action=add
udevadm trigger --type=devices --action=add
systemd-tmpfiles --prefix=/dev --create --boot
systemd-tmpfiles --create --remove --boot --exclude-prefix=/dev
