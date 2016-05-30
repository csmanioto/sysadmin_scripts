#!/bin/bash

if [ -f /etc/redhat-release ]; then
  yum -y install sysstat
fi

if [ -f /etc/lsb-release ]; then
  aptitude -y sysstat
fi

LOG="/tmp/$(hostname)_$(date +%d-%m-%Y).io"

case "$1" in

'start')
	echo "Writing LOG:  $LOG"
	iostat 5 7200 -d >> $LOG &
	echo "$!" >  /tmp/iostat.pid
	;;
'stop') 
     if [ -f /tmp/iostat.pid ]; then
	if kill -9 $(cat /tmp/iostat.pid); then
		rm -f /tmp/iostat.pid
	fi
     fi
    ;;
*) 
   echo "Use $0 com start ou stop"
   ;;
esac
