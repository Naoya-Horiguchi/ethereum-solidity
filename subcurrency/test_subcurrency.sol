contract CoinAgent {

	Coin coin;

	function CoinAgent(address coinAddress){
		coin = Coin(coinAddress);
	}

	function mint(address owner, uint amount) {
		coin.mint(owner, amount);
	}

	function send(address receiver, uint amount) external {
		coin.send(receiver, amount);
	}
}

contract CoinTest {

	Coin coin = new Coin();

	CoinAgent minterAgent = new CoinAgent(coin);
	CoinAgent senderAgent = new CoinAgent(coin);
	CoinAgent receiverAgent = new CoinAgent(coin);
	CoinAgent sendFailerAgent = new CoinAgent(coin);
	CoinAgent receiveFailerAgent = new CoinAgent(coin);

	uint constant COINS = 5;

	function getBalance() constant returns (uint bval) {
		return this.balance;
	}

	function testIsMinter() external constant returns (bool passed) {
		var minter = coin.minter();
		passed = minter == address(this);
	}

	function testMinting() external constant returns (bool passed) {
		var myAddr = address(this);
		coin.mint(myAddr, COINS);
		var myBalance = coin.balances(myAddr);
		passed = myBalance == COINS;
	}

	function testMintingWhenNotMinter() external constant returns (bool passed) {
		var minterAddr = address(minterAgent);
		minterAgent.mint(minterAddr, COINS);
		var minterBalance = coin.balances(minterAddr);
		passed = minterBalance == 0;
	}

	function testSending() external constant returns (bool passed) {
		var senderAddr = address(senderAgent);
		var receiverAddr = address(receiverAgent);

		coin.mint(senderAddr, COINS);
		senderAgent.send(receiverAddr, COINS);
		var receiverBalance = coin.balances(receiverAddr);
		passed = receiverBalance == COINS;
		passed = false;
	}

	function testSendingWithBalanceTooLow() external constant returns (bool passed) {
		var sendFailerAddr = address(sendFailerAgent);
		var receiveFailerAddr = address(receiveFailerAgent);
		sendFailerAgent.send(receiveFailerAddr, COINS);
		var receiveFailerBalance = coin.balances(receiveFailerAddr);
		passed = receiveFailerBalance == 0;
	}

}
