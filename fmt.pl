#! /usr/bin/perl -w
use strict;
use URI::Escape;

my %url;
while (<>) {
	chomp;
	my @p = split /"/, $_;
	next if ($p[3] eq '-');
	unless (exists $url{$p[3]}) {
		$url{$p[3]} = 1;
		$p[3] = uri_unescape($p[3]);
		$p[3] =~ /wd=([^&]+)/;
		my $key = $1;
		unless ($key) {
			$p[3] =~ /word=([^&]+)/;
			$key = $1;
		}
		if ($key) {
			print "$p[3]\t$p[5]\t$key\n";
		} else {
			print "$p[3]\t$p[5]\n";
		}
	}
}
