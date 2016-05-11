#
# Assuming that geth environment are created via 2node_scenario_1.sh
#
. lib/common.sh

[ ! "$NODES" ] && echo "environment variable NODES not given" && exit 1

echo_timestamp "unlock accounts"
unlock_accounts $NODES

cat <<EOF > $TMPD/.$CONTRACT.sol
contract SimpleStorage {
	uint storedData;

	function set(uint x) {
		storedData = x;
	}

	function get() constant returns (uint retVal) {
		return storedData;
	}
}
EOF

cat <<EOF > $CONTRACT/.set.js
console.log(contract_SimpleStorage.set(eth.blockNumber));
EOF

cat <<EOF > $CONTRACT/.get.js
console.log(contract_SimpleStorage.get());
EOF

for node in $NODES ; do
	run_sol_file $node 2 $TMPD/.$CONTRACT.sol
	run_js_file $node 2 $CONTRACT/.set.js
	mine_blocks $node 0 2
	run_js_file $node 2 $CONTRACT/.get.js
done
