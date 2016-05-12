echo "# Available testcases:"
find -name run.sh | while read line ; do
	echo "$(basename $(dirname $line))"
done
