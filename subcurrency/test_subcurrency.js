boolss = true;
console.log(boolss);

console.log("test start ------> ");
a = contract_CoinTest.testIsMinter();
contract_CoinTest.testMinting();
contract_CoinTest.testMintingWhenNotMinter();
d = contract_CoinTest.testSending();
console.log(a);
console.log(d);
contract_CoinTest.testSendingWithBalanceTooLow();
