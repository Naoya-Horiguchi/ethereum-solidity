. lib/common.sh

[ ! "$NODES" ] && echo "environment variable NODES not given" && exit 1

echo_timestamp "unlock accounts"
unlock_accounts $NODES

cat <<EOF > $TMPD/.$CONTRACT.sol
contract StateMachine {
	enum Stages {
		AcceptingBlindedBids,
		RevealBids,
		AnotherStage,
		AreWeDoneYet,
		Finished
	}

	Stages public stage = Stages.AcceptingBlindedBids;

	uint public creationTime = now;

	modifier atStage(Stages _stage) {
		if (stage != _stage) throw;
		_
	}
	function nextStage() internal {
		stage = Stages(uint(stage) + 1);
	}

	modifier timedTransitions() {
		if (stage == Stages.AcceptingBlindedBids &&
					now >= creationTime + 10 days)
			nextStage();
		if (stage == Stages.RevealBids &&
				now >= creationTime + 12 days)
			nextStage();
	}

	function bid()
		timedTransitions
		atStage(Stages.AcceptingBlindedBids)
	{
	}
	function reveal()
		timedTransitions
		atStage(Stages.RevealBids)
	{
	}

	modifier transitionNext()
	{
		_
		nextStage();
	}
	function g()
		timedTransitions
		atStage(Stages.AnotherStage)
		transitionNext
	{
	}
	function h()
		timedTransitions
		atStage(Stages.AreWeDoneYet)
		transitionNext
	{
	}
	function i()
		timedTransitions
		atStage(Stages.Finished)
	{
	}
}
EOF

cat <<EOF > $TMPD/.$CONTRACT.js
console.log(contract_StateMachine.bid());
EOF

for node in $NODES ; do
	check_all_balances $node

	run_sol_file $node 0 $TMPD/.$CONTRACT.sol
	run_js_file  $node 0 $TMPD/.$CONTRACT.js
done
