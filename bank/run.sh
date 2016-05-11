. lib/common.sh

[ ! "$NODES" ] && echo "environment variable NODES not given" && exit 1

echo_timestamp "unlock accounts"
unlock_accounts $NODES

cat <<EOF > $TMPD/.$CONTRACT.sol
contract Bank {

    address owner;

    mapping (address => uint) balances;

    function Bank() {
        owner = msg.sender;
    }

    function deposit(address customer) returns (bool res) {
        if (msg.value == 0) {
            return false;
        }
        balances[customer] += msg.value;
        return true;
    }

    function withdraw(address customer, uint amount) returns (bool res) {
        if (balances[customer] < amount || amount == 0)
            return false;
        balances[customer] -= amount;
        msg.sender.send(amount);
        return true;
    }

    function remove() {
        if (msg.sender == owner) {
            suicide(owner);
        }
    }
}

contract FundManager {

    address owner;
    address bank;

    function FundManager() {
        owner = msg.sender;
        bank = new Bank();
    }

    function deposit() returns (bool res) {
        if (msg.value == 0) {
            return false;
        }
        if (bank == 0x0) {
            msg.sender.send(msg.value);
            return false;
        }

        bool success = Bank(bank).deposit.value(msg.value)(msg.sender);

        if (!success) {
            msg.sender.send(msg.value);
        }
        return success;
    }

    function withdraw(uint amount) returns (bool res) {
        if (bank == 0x0) {
            return false;
        }
        bool success = Bank(bank).withdraw(msg.sender, amount);

        if (success) {
            msg.sender.send(amount);
        }
        return success;
    }
}
EOF

cat <<EOF > $TMPD/.$CONTRACT.js
contract_FundManager.deposit(3);
EOF

for node in $NODES ; do
	check_all_balances $node

	run_sol_file $node 0 $TMPD/.$CONTRACT.sol
	run_js_file  $node 0 $TMPD/.$CONTRACT.js
done
