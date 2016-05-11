#
# Define geth helper
#

set_genesis() {
	local host=$1

	cat <<EOF > $TMPD/genesis.json
{
  "nonce": "0x000000000000002a",
  "difficulty": "0x020",
  "mixhash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "coinbase": "0x0000000000000000000000000000000000000000",
  "timestamp": "0x00",
  "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "extraData": "0x",
  "gasLimit": "0x1000000"
}
EOF
	scp -q $TMPD/genesis.json $host:/tmp/genesis.json
	ssh $host "geth init /tmp/genesis.json"
}

interconnect_nodes() {
	local n1=$1
	local n2=$2
	local enode=
	local n1ip=$(ssh $n1 "host $n1" | cut -f4 -d' ')

	echo "admin.nodeInfo.enode;" | tee $TMPD/$FUNCNAME
	enode=$(do_geth_cmd $n1 $TMPD/$FUNCNAME | sed "s/\[::\]/$n1ip/")
	echo $enode > $TMPD/_enode.info
	echo "admin.addPeer($enode);" | tee $TMPD/$FUNCNAME
	do_geth_cmd $n2 $TMPD/$FUNCNAME > /dev/null
	# Check two nodes are connected (should be 1).
	echo "net.peerCount;" > $TMPD/$FUNCNAME
	do_geth_cmd $n1 $TMPD/$FUNCNAME
}

check_all_balances() {
	local node=

	echo_timestamp "check balances"
	for node in $@ ; do
		check_balances_from_list $node $TMPD/account_list
	done
}

do_geth_cmd() {
	local host=$1
	local script=$2
	local basename=$(basename $script)

	if [[ "$script" =~ .js$ ]] ; then
		# echo "scp -q $script $host:/tmp/$basename"
		scp -q $script $host:/tmp/$basename
		cat <<EOF > $script.2
geth --datadir=/root/ethereum_data --networkid 123 --verbosity $VERBOSITY --exec 'loadScript("/tmp/$basename")' attach
EOF
	else
		cat <<EOF > $script.2
geth --datadir=/root/ethereum_data --networkid 123 --verbosity $VERBOSITY --exec '$(cat $script)' attach
EOF
	fi
	scp -q $script.2 $host:/tmp/$basename.2
	ssh $host "bash /tmp/$basename.2"
}

mine_blocks() {
	local host=$1
	local account=$2
	local blocks=$3

	cat <<EOF > $TMPD/mine_blocks.js
miner.setEtherbase(eth.accounts[$account]);
miner.start(4);
admin.sleepBlocks($blocks);
miner.stop();
EOF
	do_geth_cmd $host $TMPD/mine_blocks.js
}

run_background_mining() {
	local host=$1
	local account=$2
	local blocks=$3

	cat <<EOF > $TMPD/$FUNCNAME.js
miner.setEtherbase(eth.accounts[$account]);
miner.start(1);
admin.sleepBlocks($blocks);
miner.stop();
EOF
	do_geth_cmd $host $TMPD/$FUNCNAME.js &
	echo $! >> $TMPD/run_background_mining.pid
}

stop_background_mining() {
	if [ -s $TMPD/run_background_mining.pid ] ; then
		kill -9 $(cat $TMPD/run_background_mining.pid | tr '\n' ' ')
		rm -f $TMPD/run_background_mining.pid
	fi
}

send_ether() {
	local host=$1
	local sender=$2
	local receiver=$3
	local ether=$4

	echo_timestamp "send_ether: $ether ether from $sender to $receiver"
	cat <<EOF > $TMPD/_send_ether.js
personal.unlockAccount("$sender", "passwd");
personal.unlockAccount("$receiver", "passwd");
eth.sendTransaction({
	from: "$sender",
	to: "$receiver",
	value: web3.toWei($ether, "ether")
});
EOF
	do_geth_cmd $host $TMPD/_send_ether.js
}

create_accounts() {
	local host=$1
	local nr=1
	[ "$2" ] && nr=$2

	cat <<EOF > $TMPD/create_accounts.js
for (i = 0; i < $nr; i++) {
	personal.newAccount("passwd");
}
EOF
	echo "do_geth_cmd $host $TMPD/create_accounts.js"
	do_geth_cmd $host $TMPD/create_accounts.js
}

check_balances() {
	local host=$1

	cat <<EOF > $TMPD/check_balances.js
var i = 0; 
eth.accounts.forEach(function(e) {
    console.log("  eth.accounts["+i+"]: " +  e + " \tbalance: " + web3.fromWei(eth.getBalance(e), "ether") + " ether"); 
	i++; 
});
EOF
	do_geth_cmd $host $TMPD/check_balances.js
}

check_balances_from_list() {
	local host=$1
	local list=$2
	local account=

	echo -n "" > $TMPD/check_balances.js
	for account in $(cat $list) ; do
		echo "console.log(\"  $account: \" + web3.fromWei(eth.getBalance(\"$account\"), \"ether\"))" >> $TMPD/check_balances.js
	done
	do_geth_cmd $host $TMPD/check_balances.js
}

unlock_accounts() {
	local host=

	for host in $@ ; do
		cat <<EOF > $TMPD/$FUNCNAME.js
eth.accounts.forEach(function(e) {
	personal.unlockAccount(e, "passwd"); 
});
EOF
		do_geth_cmd $host $TMPD/$FUNCNAME.js
	done
}

unlock_accounts_from_list() {
	local host=$1
	local list=$2
	local account=

	echo -n "" > $TMPD/unlock_accounts.js
	for account in $(cat $list) ; do
		echo "personal.unlockAccount(\"$account\", \"passwd\")" >> $TMPD/unlock_accounts.js
	done
	do_geth_cmd $host $TMPD/unlock_accounts.js
}

get_account_list() {
	local host=$1

	cat <<EOF > $TMPD/$FUNCNAME.js
console.log(eth.accounts);
EOF
	do_geth_cmd $host $TMPD/$FUNCNAME.js | tr ',' '\n' | grep ^0x
}

get_account_from_index() {
	local nr=$1

	sed -n ${nr}p $TMPD/account_list
}

find_first_contract() {
	local solscript=$1

	grep "^\s*contract.*{$" $solscript | sed -e 's/^\s*contract \(.*\) {/\1/'
}

save_contract() {
	local host=$1
	local account=$2
	local solscript=$3
	local contract_name=$4

	# contract definition begin with "contract <contract_name> {", so
	# if contract_name is not given by a caller, get and use the first
	# one in the given file.
	if [ ! "$contract_name" ] ; then
		contract_name="$(find_first_contract $solscript)"
		if [ ! "$contract_name" ] ; then
			echo "Not contract_name in $solscript" >&2
		fi
	fi

	cat <<EOF > $TMPD/$FUNCNAME.js
admin.setSolc("/usr/bin/solc");
primary = eth.accounts[$account];

source = "$(cat $solscript | sed -e 's/\"/\\"/g' | tr -d '\n')"
contract = eth.compile.solidity(source).$contract_name;
console.log("contract: " + contract)
txhash = eth.sendTransaction({from: primary, data: contract.code});

// make sure that transaction is mined into blockchain
miner.start(2); admin.sleepBlocks(1); miner.stop();
txreceipt = eth.getTransactionReceipt(txhash);
console.log("txreceipt:" + txreceipt);

filename = "/tmp/contractInfo.json";
contenthash = admin.saveInfo(contract.info, filename);
console.log("txreceipt.contractAddress:" + txreceipt.contractAddress);
admin.register(primary, txreceipt.contractAddress, contenthash);
admin.registerUrl(primary, contenthash, "file://" + filename);
EOF
	do_geth_cmd $host $TMPD/$FUNCNAME.js | tee /tmp/contractAddress
	scp -q $host:/tmp/contractInfo.json $TMPD/contractInfo.json
	grep ^txreceipt.contractAddress: /tmp/contractAddress | cut -f2 -d: > $TMPD/contractAddress
}

# TODO: better way to pass contractAddress and ABI definition info?
call_contract() {
	local host=$1
	shift
	local message="$@"
	local contractAddress="$(cat $TMPD/contractAddress)"

	cat <<EOF > $TMPD/$FUNCNAME.js
web3.eth.defaultAccount = eth.accounts[0];
contract = eth.contract($(get_abi_definition_from_contract_info $TMPD/contractInfo.json)).at("$contractAddress");
console.log(contract.$message);
EOF
	do_geth_cmd $host $TMPD/$FUNCNAME.js
}

get_abi_definition_from_contract_info() {
	local json=$1

	cat <<EOF > $TMPD/$FUNCNAME.py
import sys, json
fh = open(sys.argv[1], 'r')
data = json.load(fh)
print json.dumps(data["abiDefinition"])
EOF
	python $TMPD/$FUNCNAME.py $json
}

save_multiple_contracts() {
	local host=$1
	local account=$2
	local solscript=$3

	grep "^\s*contract.*{$" $solscript | sed -e 's/^\s*contract \([a-zA-Z_-]*\) .*$/\1/' | tr '\n' ' ' > $TMPD/contracts
	grep "^\s*library.*{$" $solscript | sed -e 's/^\s*library \([a-zA-Z_-]*\) .*$/\1/' | tr '\n' ' ' >> $TMPD/contracts
	for scr in $(cat $TMPD/contracts) ; do
		echo_timestamp "$scr"
		cat <<EOF > $TMPD/$FUNCNAME.$scr.js
admin.setSolc("/usr/bin/solc");
primary = eth.accounts[$account];
source = "$(cat $solscript | sed -e 's/\"/\\"/g' | tr -d '\n')"
contract = eth.compile.solidity(source).$scr
console.log("contract:" + contract);
txhash = eth.sendTransaction({from: primary, data: contract.code, gas: "1000000"});
console.log("txhash:" + txhash);
eth.getBlock("pending", true);
eth.getBlock("latest");

miner.setEtherbase(primary); miner.start(4); admin.sleepBlocks(2); miner.stop();
txreceipt = eth.getTransactionReceipt(txhash);
console.log("txreceipt:" + txreceipt);

filename = "/tmp/contractInfo.$scr.json";
contenthash = admin.saveInfo(contract.info, filename);
console.log("txreceipt.contractAddress:" + txreceipt.contractAddress);
admin.register(primary, txreceipt.contractAddress, contenthash);
admin.registerUrl(primary, contenthash, "file://" + filename);
EOF
		do_geth_cmd $host $TMPD/$FUNCNAME.$scr.js | tee /tmp/contractAddress.$scr
		scp -q $host:/tmp/contractInfo.$scr.json $TMPD/contractInfo.$scr.json
		grep ^txreceipt.contractAddress: /tmp/contractAddress.$scr | cut -f2 -d: > $TMPD/contractAddress.$scr
	done
}

run_sol_file() {
	local host=$1
	local account=$2
	shift 2
	local files=$@
	local file=

	echo "" > $TMPD/.run_sol_file.sol
	for file in $files ; do
		cat $file >> $TMPD/.run_sol_file.sol
	done

	echo_timestamp "push Solidity files: $files"
	save_multiple_contracts $host $account $TMPD/.run_sol_file.sol
}

run_js_file() {
	local host=$1
	local account=$2
	local file=$3

	echo_timestamp "call JavaScirpt file $file"
	load_contract $host $account $file
}

load_contract() {
	local host=$1
	local account=$2
	local code=$3
	local tmpf=$TMPD/$(basename $code).tmp

	echo "web3.eth.defaultAccount = eth.accounts[$account];" > $tmpf
	for scr in $(cat $TMPD/contracts) ; do
		local contractAddress_$scr="$(cat $TMPD/contractAddress.$scr)"
		cat <<EOF >> $tmpf
contract_$scr = eth.contract($(get_abi_definition_from_contract_info $TMPD/contractInfo.$scr.json)).at("$(cat $TMPD/contractAddress.$scr)");
EOF
	done
	cat $code >> $tmpf

	echo "--------"
	cat $tmpf
	echo "--------"
	do_geth_cmd $host $tmpf
}
