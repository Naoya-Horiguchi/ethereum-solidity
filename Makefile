#
# You need give some environment variable.
#  - CONTRACT: testcase name you want to run
#  - NODES: hostname you want to run the test on (you need to be able to
#    access the host with ssh without password authentication)
#  - INITIALIZE (available only when CONTRACT=onenode): if some string is
#    set, existing ethereum data (on $HOME/.ethereum) is removed and whole
#    blockchain is initialized.
#
run:
	@bash run_generic.sh

show_testcase:
	@bash lib/show_testcases.sh

show_accounts:
	@bash lib/show_accounts.sh

mine_one_block:
	@bash lib/mine_one_block.sh
