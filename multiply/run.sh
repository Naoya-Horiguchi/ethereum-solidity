. lib/common.sh

[ ! "$NODES" ] && echo "environment variable NODES not given" && exit 1

echo_timestamp "unlock accounts"
unlock_accounts $NODES 2> /dev/null

cat <<EOF > $TMPD/.$CONTRACT.sol
contract test {
	function multiply(uint a) returns(uint d) {
		return a * 7;
	}
}
EOF

cat <<EOF > $TMPD/.$CONTRACT.js
console.log(contract_test.multiply.call(7));
console.log(contract_test.multiply.call(9));
EOF

run_background_log_collector $NODES

for node in $NODES ; do
	check_all_balances $node

	run_sol_file $node 0 $TMPD/.$CONTRACT.sol
	run_js_file  $node 0 $TMPD/.$CONTRACT.js
done

stop_backgroud_log_collector $NODES
