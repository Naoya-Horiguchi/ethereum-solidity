if [ ! "$CONTRACT" ] ; then
	echo "environment variable CONTRACT not given."
	exit 1
fi

if [ ! -e "$CONTRACT/run.sh" ] ; then
	echo "$CONTRACT/run.sh not found."
	exit 1
fi

bash $CONTRACT/run.sh
