. lib/common.sh

[ ! "$NODES" ] && echo "environment variable NODES not given" && exit 1

echo_timestamp "unlock accounts"
unlock_accounts $NODES

cat <<EOF > $TMPD/.$CONTRACT.sol
contract Users {
	mapping (bytes32 => address) public users;

	event Print(string out);

	function Users() {
		Print("test");
	}

	function register(bytes32 name) {
		if (users[name] == 0 && name != "") {
			users[name] = msg.sender;
		}
	}

	function unregister(bytes32 name) {
		if (users[name] != 0 && name != "") {
			users[name] = 0x0;
		}
	}

	function print() {
        Print("text");
	}
	
}
EOF

cat <<EOF > $TMPD/.$CONTRACT.js
contract_Users.Print(function(result) {
    console.log(result);
})
contract_Users.print();
miner.setEtherbase(eth.accounts[0]); miner.start(4); admin.sleepBlocks(2); miner.stop();
contract_Users.register("sample");
contract_Users.unregister("sample");
miner.setEtherbase(eth.accounts[0]); miner.start(4); admin.sleepBlocks(2); miner.stop();
contract_Users.print();
console.log("-------");
EOF

for node in $NODES ; do
	check_all_balances $node

	run_sol_file $node 0 $TMPD/.$CONTRACT.sol
	run_js_file  $node 0 $TMPD/.$CONTRACT.js
done
