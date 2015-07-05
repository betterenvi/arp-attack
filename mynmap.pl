#! /usr/bin/perl -w
use strict;
my $ip4_reg = qr /\d+(?:\.\d+){3}/;
my $hwaddr_reg = qr /[\da-fA-f]{2}(?::[\da-fA-f]{2}){5}/;

exit 1 unless $#ARGV == 1;

my $nmapret = `nmap -sP $ARGV[1]`;
exit 1 unless ($nmapret =~ /Nmap done: (\d+) IP addresses \((\d+) hosts up\) scanned in (\d+(?:\.\d+)?) seconds/);
print "$1 $2 $3\n";

my @hosts = ($nmapret =~ /Nmap scan report for ($ip4_reg)\n[^\n]+\nMAC Address: ($hwaddr_reg) \((.*)\)\n/g);

foreach (0..$#hosts) {
	next unless $_ % 3 == 0;
    next if $hosts[$_] eq $ARGV[0];
	print "$hosts[$_]\t$hosts[$_+1]\t$hosts[$_+2]\n";
}
