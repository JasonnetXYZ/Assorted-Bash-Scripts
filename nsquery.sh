#!/bin/bash

# Check if a file path is used for domains list
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 domains.txt"
    exit 1
fi

# Domains list
domains_file="$1"

# Check if the file exists
if [ ! -f "$domains_file" ]; then
    echo "File not found: $domains_file"
    exit 1
fi

# Main loop
while IFS= read -r domain; do
    # Skip empty lines
    if [ -z "$domain" ]; then
        continue
    fi

    echo "Domain: $domain"
    echo "Nameservers:"

    # Query the domain's nameservers and print them
    dig +short NS "$domain" @8.8.8.8 | while IFS= read -r nameserver; do
        echo " - $nameserver"
    done

    echo "" # Print a newline for easier reading
done < "$domains_file"
