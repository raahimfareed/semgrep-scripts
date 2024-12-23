#! /usr/bin/env sh
set -e
current_date=$(date +"%y%m%d-%H%M%S")

echo "Running semgrep"

semgrep scan --output ${current_date}.json --json

echo "Output file ${current_date}.json created"
