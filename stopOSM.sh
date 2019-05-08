#!/bin/sh
#Lever      modified 2013/8/21 10:02:27

program="pidstat|t_stat|startOSM.sh|mpstat"
ps -ef --sort=command | grep -P "$program" | grep -v "$program"

printf "would you like to kill these process ? [y/n]"
read response

if [ "$response" = "y" -o "$response" = "Y" ]
then
  ps -ef | grep -P "$program" | grep -v "$program" | awk '{print $2}' | xargs kill -15
else
  echo "do nothing."
fi