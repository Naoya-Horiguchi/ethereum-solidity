. lib/common.sh

[ ! "$NODES" ] && echo "environment variable NODES not given" && exit 1

node=$NODES # get first one

mine_blocks $node 0 1
