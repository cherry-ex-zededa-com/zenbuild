#!/bin/sh
#
# This *really* needs to be replaced with tini+monit ASAP.

# Start with a default content for resolv.conf
echo 'nameserver 8.8.8.8' > /etc/resolv.conf

# Mount /config
CFGDEV=$(cgpt find -t 13307e62-cd9c-4920-8f9b-91b45828b798)
if [ ! "x$CFGDEV" = "x" ]; then
    mount $CFGDEV /config
fi

# Need to disable H/W TCP offload since it seems to mess us up
ethtool -K eth0 gro off
ethtool -K eth1 gro off
ethtool -K eth0 sg off
ethtool -K eth1 sg off

# For convenice's sake we're putting SSH inisde of a root container 
/usr/sbin/sshd

# Finally, we need to start Xen
XENCONSOLED_ARGS='--log=all --log-dir=/var/log/xen' /etc/init.d/xencommons start

# This is an optional component - only run it if it is there
if [ -f /opt/zededa/bin/device-steps.sh ]; then
    /opt/zededa/bin/device-steps.sh -w >/var/log/device-steps.log 2>&1
fi

tail -f /var/log/*.log
