#
# Assuming that geth environment are created via 2node_scenario_1.sh
#
. lib/common.sh

[ ! "$NODES" ] && echo "environment variable NODES not given" && exit 1

echo_timestamp "unlock accounts"
unlock_accounts $NODES

cat <<EOF > $TMPD/.$CONTRACT.sol
library Ints {

	struct Pair {
		int x;
		int y;
	}

	function max(Pair storage self) constant returns (int) {
		if (self.x >= self.y)
			return self.x;
		else
			return self.y;
	}

}

contract IntsUser {

	using Ints for Ints.Pair;

	Ints.Pair _ints;

	function IntsUser() {
		_ints.x = 3;
		_ints.y = 1;
	}

	function setpair(int a) {
		_ints.x = 2;
		_ints.y = 7;
	}

	function max() constant returns (int) {
		return _ints.max();
	}

}
EOF

cat <<EOF > $TMPD/.$CONTRACT.2.sol
contract IntsUser {

	struct Pair {
		int x;
		int y;
	}

	Pair _ints;

	function max() constant returns (int retVal) {
		if (_ints.x >= _ints.y)
			return _ints.x;
		else
			return _ints.y;
	}

	function IntsUser() {
		_ints = Pair(4, -5);
	}

	function setpair(int a) {
		_ints.x = a;
	}

}
EOF

cat <<EOF > $TMPD/.$CONTRACT.set.js
contract_IntsUser.setpair(8);
EOF

cat <<EOF > $TMPD/.$CONTRACT.getmax.js
console.log(contract_IntsUser.max());
EOF

for node in $NODES ; do
	check_all_balances $node

	# TODO: library doesn't work?
	# run_sol_file $node 2 $TMPD/.$CONTRACT.sol
	run_sol_file $node 2 $TMPD/.$CONTRACT.2.sol
	run_js_file $node 2 $TMPD/.$CONTRACT.set.js
	mine_blocks $node 0 2
	run_js_file $node 2 $TMPD/.$CONTRACT.getmax.js
done
