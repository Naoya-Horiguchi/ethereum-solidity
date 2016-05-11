#
# Define common helpers
#
if [ ! "$TMPD" ] ; then
	TMPD=$HOME/ethereum_data/$(ls -1t $HOME/ethereum_data/ | head -n1)
fi
mkdir -p $TMPD
WAITSEC=5
VERBOSITY=3
LDIR=$(dirname $(readlink -f $BASH_SOURCE))

. $LDIR/helpers.sh

cleanup_previous_process() {
	local host=$1

	if [ "$INITIALIZE" ] ; then
		ssh $host "rm -rf ethereum_data/ .ethereum/"
	fi
    stop_backgroud_log_collector $host
    ssh $host "pkill -9 -f geth"
	ssh $host "echo 3 > /proc/sys/vm/drop_caches"
}

prepare() {
	local host=$1

	ssh $host "
		mkdir -p .ethereum
		mkdir -p ethereum_data
	"
}

run_background_geth_process() {
	local host=$1

	ssh $host "geth $GETH_OPTS" &
}

run_background_log_collector() {
	local host=

	for host in $@ ; do
		scp -q $LDIR/background_log_collector.sh $host:ethereum_data/background_log_collector.sh
		ssh $host "nohup bash ethereum_data/background_log_collector.sh > /dev/null 2> /dev/null" &
	done
}

stop_backgroud_log_collector() {
	local host=

	for host in $@ ; do
		ssh $host "pkill -9 -f background_log_collector.sh"
	done
}

echo_timestamp() {
	local ts="$(date +'%y/%m/%d %H:%M:%S')"

	echo "[$ts] $@"
}
