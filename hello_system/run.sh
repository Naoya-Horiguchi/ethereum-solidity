. lib/common.sh

[ ! "$NODES" ] && echo "environment variable NODES not given" && exit 1

echo_timestamp "unlock accounts"
unlock_accounts $NODES

cat <<EOF > $TMPD/.$CONTRACT.sol
contract HelloSystem {
    address owner;

    function HelloSystem() {
        owner = msg.sender;
    }

    function remove() {
        if (msg.sender == owner) {
            suicide(owner);
        }
    }
}

contract HelloFactory {

    function createHS() returns (address hsAddr) {
        return address(new HelloSystem());
    }

    function deleteHS(address hs) {
        HelloSystem(hs).remove();
    }
}
EOF

cat <<EOF > $TMPD/.$CONTRACT.js
var hs = contract_HelloFactory.createHS();
contract_HelloFactory.deleteHS(hs);
EOF

for node in $NODES ; do
	check_all_balances $node

	run_sol_file $node 0 $TMPD/.$CONTRACT.sol
	run_js_file  $node 0 $TMPD/.$CONTRACT.js
done
