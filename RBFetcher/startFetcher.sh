#!/bin/zsh
while 1=1
do
	echo "Starting Fetcher..." >>fetched.out
	./Fetcher -threads 80 >>fetched.out 2>&1 
	echo "Fetcher died due to" >>fetched.out
	tail -100 fetched.out	>>fetched.out
	echo "Moving intermediate file:" >>fetched.out
	mv -f fetched/fetched.out.tinkerbell.intermediate fetched/fetched.out.$$
	sleep 10;
done
