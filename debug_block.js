function debugBlock() { 
	// web3.eth.getBlock(3);
	var info = web3.eth.getBlock(3);
	console.log(info);
};

debugBlock();
