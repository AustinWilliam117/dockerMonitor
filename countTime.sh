#!/bin/bash

now=$(date "+%Y-%m-%d_%H_%M_%S")

while true;do printf "\n$(date "+%Y-%m-%d_%H_%M_%S"):\n" | tee --append stats_$now.txt;  docker stats --no-stream audiolistening_42 | tee --append stats_$now.txt; sleep 1; done
