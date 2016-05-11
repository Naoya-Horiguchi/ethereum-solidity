. lib/common.sh

[ ! "$NODES" ] && echo "environment variable NODES not given" && exit 1

echo_timestamp "unlock accounts"
unlock_accounts $NODES

cat <<EOF > $TMPD/.$CONTRACT.js
function getMinedBlocks(miner, startBlockNumber, endBlockNumber) {
	console.log("Searching for miner " + miner + " within blocks "  + startBlockNumber + " and " + endBlockNumber);

	for (var i = startBlockNumber; i <= endBlockNumber ; i++) {
		if (i % 1000 == 0) {
			console.log("Searching block " + i);
		}
		var block = eth.getBlock(i);
		if (block != null) {
			if (block.miner == miner || miner == "*") {
				console.log("Found block " + block.number);
				printBlock(block);
			}
			if (block.uncles != null) {
				for (var j = 0; j < 2; j++) {
					var uncle = eth.getUncle(i, j);
			   		if (uncle != null) {
						if (uncle.miner == miner || miner == "*") {
							console.log("Found uncle " + block.number + " uncle " + j);
							printUncle(block, j, uncle);
						}
					}
				}
			}
		}
	}
}

function printTransaction(txHash) {
	var tx = eth.getTransaction(txHash);
	if (tx != null) {
		console.log("  tx hash           : " + tx.hash);
		console.log("    nonce           : " + tx.nonce);
		console.log("    blockHash       : " + tx.blockHash);
		console.log("    blockNumber     : " + tx.blockNumber);
		console.log("    transactionIndex: " + tx.transactionIndex);
		console.log("    from            : " + tx.from);
		console.log("    to              : " + tx.to);
		console.log("    value           : " + tx.value);
		console.log("    gasPrice        : " + tx.gasPrice);
		console.log("    gas             : " + tx.gas);
		console.log("    input           : " + tx.input);
	}
}

function printBlock(block) {
	console.log("Block number      : " + block.number);
	console.log("  hash            : " + block.hash);
	console.log("  parentHash      : " + block.parentHash);
	console.log("  nonce           : " + block.nonce);
	console.log("  sha3Uncles      : " + block.sha3Uncles);
	console.log("  logsBloom       : " + block.logsBloom);
	console.log("  transactionsRoot: " + block.transactionsRoot);
	console.log("  stateRoot       : " + block.stateRoot);
	console.log("  miner           : " + block.miner);
	console.log("  difficulty      : " + block.difficulty);
	console.log("  totalDifficulty : " + block.totalDifficulty);
	console.log("  extraData       : " + block.extraData);
	console.log("  size            : " + block.size);
	console.log("  gasLimit        : " + block.gasLimit);
	console.log("  gasUsed         : " + block.gasUsed);
	console.log("  timestamp       : " + block.timestamp);
	console.log("  transactions    : " + block.transactions);
	console.log("  uncles          : " + block.uncles);
	if (block.transactions != null) {
    	console.log("--- transactions ---");
		block.transactions.forEach( function(e) {
			printTransaction(e);
		})
	}
}

function printUncle(block, uncleNumber, uncle) {
	console.log("Block number      : " + block.number + " , uncle position: " + uncleNumber);
	console.log("  Uncle number    : " + uncle.number);
	console.log("  hash            : " + uncle.hash);
	console.log("  parentHash      : " + uncle.parentHash);
	console.log("  nonce           : " + uncle.nonce);
	console.log("  sha3Uncles      : " + uncle.sha3Uncles);
	console.log("  logsBloom       : " + uncle.logsBloom);
	console.log("  transactionsRoot: " + uncle.transactionsRoot);
	console.log("  stateRoot       : " + uncle.stateRoot);
	console.log("  miner           : " + uncle.miner);
	console.log("  difficulty      : " + uncle.difficulty);
	console.log("  totalDifficulty : " + uncle.totalDifficulty);
	console.log("  extraData       : " + uncle.extraData);
	console.log("  size            : " + uncle.size);
	console.log("  gasLimit        : " + uncle.gasLimit);
	console.log("  gasUsed         : " + uncle.gasUsed);
	console.log("  timestamp       : " + uncle.timestamp);
	console.log("  transactions    : " + uncle.transactions);
}

function getMyMinedBlocks(startBlockNumber, endBlockNumber) {
	getMinedBlocks(eth.accounts[0], startBlockNumber, endBlockNumber);
}

getMyMinedBlocks(0, eth.blockNumber);
// contract_block_explorer.getMinedBlocks("0x7eb18877113115cd2b1cd3618e94ed28d70a0344", 578, 580);
EOF

for node in $NODES ; do
	check_all_balances $node

	run_js_file  $node 0 $TMPD/.$CONTRACT.js | tee blocks
done
