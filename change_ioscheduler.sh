#/bin/bash

IO_S="mq-deadline"
for f in /sys/block/nvme0n?/queue/scheduler; do echo $IO_S > $f; cat $f; done
