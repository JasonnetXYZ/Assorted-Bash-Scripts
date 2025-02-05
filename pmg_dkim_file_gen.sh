#!/bin/bash

# PMG DKIM KEY
DKIM_KEY='("v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvTX6vG2ZFfYbzXYnUk1qpLAtghRYf+Q6wlt6FsCdO2EQnXwsY+rg2g/EBt9idCnn2oKg7fElD"
          "jv+eZQKsupsSovRX28VKkXHGR/rljxrlTcClcKmfvNHlvbmRLgBWecieT6CaIjc1JITBMjsO7riy2OhBk7JGB2gnhdRp6nZRV9MJTWrufD7EcE9yh5lRZdQ6Hj2nScIdS4iqu"
          "0dzTomJQ5h39ACQS6CHhzQr6Pm03bbQxprdtJ00gT6p2b590YzM6UceTxmFhOS3bmdijwEuitnkm8ZMeNuhHeLwRXhJ8ewQ8MLmGvOW889pqmKRC6U79nxIEW0yrMFU7KEO0ySRQIDAQAB" )'

# Subdomain list file - One subdomain per line
SUBDOMAIN_FILE="subdomains.txt"

# Output file
OUTPUT_FILE="dkim_records.txt"

# Make sure subdomain list file exists
if [[ ! -f "$SUBDOMAIN_FILE" ]]; then
    echo "Error: Subdomain file '$SUBDOMAIN_FILE' not found!"
    exit 1
fi

# Create or empty the output file
> "$OUTPUT_FILE"

# Read list and add record 
while read -r SUBDOMAIN; do
    # Skip empty lines
    [[ -z "$SUBDOMAIN" ]] && continue
    
    # Generate DKIM record
    echo "pmg._domainkey.$SUBDOMAIN IN TXT $DKIM_KEY" >> "$OUTPUT_FILE"
done < "$SUBDOMAIN_FILE"

echo "Jason, don't forget to double check each record in '$OUTPUT_FILE'."

