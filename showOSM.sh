#!/bin/sh
#Lever      modified 2013/8/21 10:02:27

program="pidstat|t_stat|startOSM.sh|mpstat"
ps -ef --sort=command | grep -P "$program" | grep -v "$program"