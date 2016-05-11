if [ "$INITIALIZE" ] ; then
	rm -rf $HOME/ethereum_data/*
	TMPD=$HOME/ethereum_data/$(date +%s)
fi

. lib/common.sh

GETH_OPTS="--datadir=/root/ethereum_data --networkid 123 --olympic -rpc --rpcaddr localhost --rpcport 8545  --ipcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3 --verbosity $VERBOSITY"

echo_timestamp "datadir is $TMPD"

[ ! "$NODES" ] && echo "environment variable NODES not given" && exit 1

for node in $NODES ; do
	echo_timestamp "setup $node"
	echo_timestamp "cleanup_previous_process"
	cleanup_previous_process $node
	echo_timestamp "prepare"
	prepare $node
	echo_timestamp "set_genesis"
	set_genesis $node
	echo_timestamp "run_background_geth_process"
	run_background_geth_process $node
done

echo_timestamp "waiting $WAITSEC sec to wait geth server to be prepared."
sleep $WAITSEC
echo_timestamp "wait done"

for node in $NODES ; do
	echo_timestamp "link ~/ethereum_data/geth.ipc to .ethereum/geth.ipc"
	ssh $node "ln -sf \$HOME/ethereum_data/geth.ipc \$HOME/.ethereum/geth.ipc"
done

# Interconnect two nodes within ethereum network.
for node in $NODES ; do
	for target in $NODES ; do
		[ "$node" == "$target" ] && continue
		echo_timestamp "interconnect nodes $node and $target"
		interconnect_nodes $node $target
	done
done

for node in $NODES ; do
	echo_timestamp "create 3 accounts on each node"
	create_accounts $node 3
	get_account_list $node >> $TMPD/account_list
	cat $TMPD/account_list

	check_all_balances $node

	echo_timestamp "mine_blocks"
	mine_blocks $node 0 2
	mine_blocks $node 2 2

	check_all_balances $node

	echo_timestamp "send_ether 1 ether from $(get_account_from_index 1) to $(get_account_from_index 2)"
	check_balances $node
	send_ether $node $(get_account_from_index 1) $(get_account_from_index 2) 1
	mine_blocks $node 2 1

	check_all_balances $node
done
