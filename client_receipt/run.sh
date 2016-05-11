. lib/common.sh

[ ! "$NODES" ] && echo "environment variable NODES not given" && exit 1

echo_timestamp "unlock accounts"
unlock_accounts $NODES

cat <<EOF > $TMPD/.$CONTRACT.sol
contract ClientReceipt {
    event Deposit(
        address indexed _from,
        bytes32 indexed _id,
        uint _value
    );

    function deposit(bytes32 _id) {
        Deposit(msg.sender, _id, msg.value);
    }
}
EOF

cat <<EOF > $TMPD/.$CONTRACT.js
var event = contract_ClientReceipt.Deposit();

event.watch(function(error, result){
    if (!error)
        console.log(result);
});

var event = contract_ClientReceipt.Deposit(function(error, result) {
    if (!error)
        console.log(result);
});

contract_ClientReceipt.deposit(eth.accounts[0]);
miner.setEtherbase(eth.accounts[0]); miner.start(4); admin.sleepBlocks(2); miner.stop()
EOF

for node in $NODES ; do
	check_all_balances $node

	run_sol_file $node 0 $TMPD/.$CONTRACT.sol
	run_js_file  $node 0 $TMPD/.$CONTRACT.js
done
