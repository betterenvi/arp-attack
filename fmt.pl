#! /usr/bin/perl -w
use strict;
use URI::Escape;

# 该hash用于去除重复访问的url
my %url;

while (<>) {
	chomp;
	my @p = split /"/, $_;
	# 去除掉无意义的URL输出
	next if ($p[3] eq '-');
	unless (exists $url{$p[3]}) {
		$url{$p[3]} = 1;	# hash去重
		$p[3] = uri_unescape($p[3]);	# 中文转码
		$p[3] =~ /wd=([^&]+)/;	# 提取百度搜索关键词
		my $key = $1;
		unless ($key) {
			$p[3] =~ /word=([^&]+)/;
			$key = $1;
		}
		# 输出URL, 浏览器和系统信息以及百度搜索关键词
		if ($key) {
			print "$p[3]\t$p[5]\t$key\n";
		} else {
			print "$p[3]\t$p[5]\n";
		}
	}
}
