#!/bin/zsh
while 1=1
do
	echo "Starting Fetcher...";
	./Fetcher -threads 80 >>fetched.out 2>&1 
	echo "Fetcher died due to"
	tail -100 fetched.out
	echo "Moving intermediate file:"
	mv -f fetched/fetched.out.tinkerbell.intermediate fetched/fetched.out.$$
	sleep 10;
done
