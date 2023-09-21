#!/bin/bash
# Exit immediately if a command exits with a non-zero status
# VERSION 0.3 by d3vilh@github.com aka Mr. Philipp
set -e

# Benchmarking the start time get
start_time=$(date +%s)

printf "\033[1;34mBuilding OpenVPN Server Image.\033[0m\n"
docker build --force-rm=true -t d3vilh/openvpn-server .

# Benchmarking the end time record
end_time=$(date +%s)

# Calculate the execution time in seconds
execution_time=$((end_time - start_time))

# Calculate the execution time in minutes and seconds
minutes=$((execution_time / 60))
seconds=$((execution_time % 60))

# Print the execution time in mm:ss format
printf "\033[1;34mExecution time: %02d:%02d\033[0m (%d sec)\n" $minutes $seconds $execution_time