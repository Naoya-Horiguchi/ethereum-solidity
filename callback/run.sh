. lib/common.sh

[ ! "$NODES" ] && echo "environment variable NODES not given" && exit 1

echo_timestamp "unlock accounts"
unlock_accounts $NODES 2> /dev/null

cat <<EOF > $TMPD/.$CONTRACT.sol
contract Test {
	function() { x = 1; }
	uint x;
}

contract Rejector {
	function() { throw; }
}

contract Caller {
	function callTest(address testAddress) constant {
		Test(testAddress).call(0xabcdef01);
		Rejector r = Rejector(0x123);
		r.send(2 ether);
	}
}
EOF

cat <<EOF > $TMPD/.$CONTRACT.js
console.log(contract_Caller.callTest("0xabcd1023"));
EOF

for node in $NODES ; do
	check_all_balances $node

	run_sol_file $node 0 $TMPD/.$CONTRACT.sol
	run_js_file  $node 0 $TMPD/.$CONTRACT.js
done
