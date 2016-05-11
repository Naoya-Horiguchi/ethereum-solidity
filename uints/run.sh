. lib/common.sh

[ ! "$NODES" ] && echo "environment variable NODES not given" && exit 1

echo_timestamp "unlock accounts"
unlock_accounts $NODES

cat <<EOF > $TMPD/.$CONTRACT.sol
library Uints {

	function sum(uint[] storage self) constant returns (uint s) {
		for (uint i = 0; i < self.length; i++)
			s += self[i];
	}

	function max(uint[] storage self) constant returns (uint max){
		for (uint i = 0; i < self.length; i++) {
			var x = self[i];
			if (x > max)
				max = x;
		}
	}

}

contract UintsUser {

	using Uints for uint[];

	uint[] _uints;

	function UintsUser() {
		_uints.push(4);
		_uints.push(5);
		_uints.push(2);
	}

	function sum() constant returns (uint) {
		return _uints.sum();
	}

	function max() constant returns (uint) {
		return _uints.max();
	}

}
EOF

cat <<EOF > $TMPD/.$CONTRACT.js
console.log(contract_UintsUser.sum());
console.log(contract_UintsUser.max());
EOF

for node in $NODES ; do
	check_all_balances $node

	run_sol_file $node 0 $TMPD/.$CONTRACT.sol
	mine_blocks $node 1 2
	run_js_file  $node 0 $TMPD/.$CONTRACT.js
done
