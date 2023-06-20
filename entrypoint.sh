#!/bin/sh
systemctl start nginx
/usr/bin/semaphore service --config=/root/config.json