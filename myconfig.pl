#! /usr/bin/perl -w
use strict;
# ipv4和硬件地址的提取正则表达式
my $ip4_reg = qr /\d+(?:\.\d+){3}/;
my $hwaddr_reg = qr /[\da-fA-f]{2}(?::[\da-fA-f]{2}){5}/;

# 提取解析ifconfig命令的输出
foreach(split "\n\n", `ifconfig`) {
	next if /^lo/;
	next unless /^(\w+)\s+Link\sencap:(\w+)\s+HWaddr\s+($hwaddr_reg)\s+
				inet\saddr:($ip4_reg)(?:.*?)Mask:($ip4_reg)/sx;
	print "$1 $2 $4 $5 $3";
	my $cidr = getCIDR($4, $5);
	`route` =~ /default\s+($ip4_reg)/;
	print " $1 $cidr";
}

# 通过ip和掩玛获取所在网络的CIDR表示
sub getCIDR {
	my ($ip, $mask) = @_;
	return unless ($ip =~ /$ip4_reg/);
	return unless ($mask =~ /$ip4_reg/);

	my $cidr = 32;
	foreach (reverse split /\./, $mask) {
		if ($_ == 0) {
			$cidr -= 8;
		} elsif ($_ == 255) {
			last;
		} else {
			for ( ; ($_ & 1) == 0 ; $_>>=1) {
				$cidr--;
			}
		}
	}
	"$ip\/$cidr";
}
