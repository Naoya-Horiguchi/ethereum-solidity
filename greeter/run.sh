. lib/common.sh

[ ! "$NODES" ] && echo "environment variable NODES not given" && exit 1

echo_timestamp "unlock accounts"
unlock_accounts $NODES

cat <<EOF > $TMPD/.$CONTRACT.sol
contract mortal {
	address owner;

	function mortal() { owner = msg.sender; }
	function kill() { if (msg.sender == owner) suicide(owner); }
}

contract greeter is mortal {
	string greeting;

	function greeter(string _greeting) public {
		greeting = _greeting;
	}

	function greet() constant returns (string) {
		return "hello world";
	}
}
EOF

cat <<EOF > $TMPD/.$CONTRACT.js
console.log("Current ethereum causes unhandled excpetion.");
console.log(contract_greeter.greet.call());
EOF

for node in $NODES ; do
	check_all_balances $node

	run_sol_file $node 0 $TMPD/.$CONTRACT.sol
	run_js_file  $node 0 $TMPD/.$CONTRACT.js
done
