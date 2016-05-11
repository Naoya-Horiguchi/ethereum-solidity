contract IntsUser {

	struct Pair {
		int x;
		int y;
	}

	Pair _ints;

	function max() constant returns (int retVal) {
		if (_ints.x >= _ints.y)
			return _ints.x;
		else
			return _ints.y;
	}

	function IntsUser() {
		_ints = Pair(4, -5);
	}

	function setpair(int a) {
		_ints.x = a;
	}

}
