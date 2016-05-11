#
# Assuming that geth environment are created via 2node_scenario_1.sh
#
. lib/common.sh

[ ! "$NODES" ] && echo "environment variable NODES not given" && exit 1

echo_timestamp "unlock accounts"
unlock_accounts $NODES

cat <<EOF > $TMPD/.$CONTRACT.sol
contract Coin {
    address public minter;
    mapping (address => uint) public balances;

    event Sent(address from, address to, uint amount);

    function Coin() {
        minter = msg.sender;
    }

    function mint(address receiver, uint amount) {
        if (msg.sender != minter) return;
        balances[receiver] += amount;
    }

    function send(address receiver, uint amount) {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        Sent(msg.sender, receiver, amount);
    }

    function queryBalance(address addr) constant returns (uint balance) {
        return balances[addr];
    }
}
EOF

cat <<EOF > $TMPD/.$CONTRACT.js
contract_Coin.Sent(function(error, result) {
    if (!error) {
        console.log("Coin transfer: " + result.args.amount +
            " coins were sent from " + result.args.from +
            " to " + result.args.to + ".");
        console.log("Balances now:\n" +
            "Sender: " + Coin.balances.call(result.args.from) +
            "Receiver: " + Coin.balances.call(result.args.to));
    }
})

contract_Coin.mint(eth.accounts[0], 10);
contract_Coin.send(eth.accounts[0], 10);

miner.setEtherbase(eth.accounts[0]); miner.start(4); admin.sleepBlocks(2); miner.stop();

console.log("-------");
console.log(contract_CoinTest.getBalance());
console.log("-------");
console.log(contract_CoinTest.testIsMinter());
console.log("-------");
// console.log(contract_CoinTest.testMinting());
// console.log(contract_CoinTest.testMintingWhenNotMinter());
// console.log(contract_CoinTest.testSending());
// console.log(contract_CoinTest.testSendingWithBalanceTooLow());
miner.setEtherbase(eth.accounts[0]);
miner.start(4); admin.sleepBlocks(2); miner.stop();
console.log("-------");

EOF

for node in $NODES ; do
	check_all_balances $node
	run_sol_file $node 0 $TMPD/.$CONTRACT.sol $CONTRACT/test_subcurrency.sol
	mine_blocks  $node 1 2
	run_js_file  $node 0 $TMPD/.$CONTRACT.js
done
