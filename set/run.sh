#
# Assuming that geth environment are created via 2node_scenario_1.sh
#
. lib/common.sh

[ ! "$NODES" ] && echo "environment variable NODES not given" && exit 1

echo_timestamp "unlock accounts"
unlock_accounts $NODES

cat <<EOF > $TMPD/.$CONTRACT.sol
library Set {
	struct Data { mapping(uint => bool) flags; }
	
	function insert(Data storage self, uint value)
		returns (bool)
	{
		if (self.flags[value])
			return false;
		self.flags[value] = true;
		return true;
	}
	
	function remove(Data storage self, uint value)
		returns (bool)
	{
		if (!self.flags[value])
			return false;
		self.flags[value] = false;
		return true;
	}
	
	function contains(Data storage self, uint value)
		returns (bool)
	{
		return self.flags[value];
	}
}

contract C {
	Set.Data knownValues;

	function register(uint value) {
		if (!Set.insert(knownValues, value))
			throw;
	}

	function contains(uint value) constant returns (bool) {
		return Set.contains(knownValues, value);
	}
}
EOF

cat <<EOF > $TMPD/.$CONTRACT.js
contract_C.register(3);
miner.setEtherbase(eth.accounts[0]); miner.start(4); admin.sleepBlocks(2); miner.stop();
console.log(contract_C.contains(1));
console.log(contract_C.contains(2));
console.log(contract_C.contains(3));
contract_C.contains(3);
contract_C.flags;
EOF

for node in $NODES ; do
	check_all_balances $node

	run_sol_file $node 0 $TMPD/.$CONTRACT.sol
	mine_blocks $node 1 2
	run_js_file  $node 0 $TMPD/.$CONTRACT.js
done
