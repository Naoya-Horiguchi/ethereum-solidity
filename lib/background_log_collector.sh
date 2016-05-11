GETHPID=$(pidof geth)
RESDIR=/tmp/$(hostname)_$(date +%s)

mkdir -p $RESDIR

vmstat -n 1 > $RESDIR/vmstat &
VMSTATPID=$!

check_status() {
	while true ; do
		cat /proc/net/dev >> $RESDIR/netdev
		if kill -0 $GETPID > /dev/null ; then
			cat /proc/$GETHPID/status >> $RESDIR/status
		fi
		sleep 1
	done
}

check_status &
CHECKSTATUSPID=$!

stop_logger() {
	kill $VMSTATPID $CHECKSTATUSPID
}

trap stop_logger SIGINT SIGUSR1

sleep 10000
