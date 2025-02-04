#!/bin/bash

# Enter SMTP server and port
read -p "Enter SMTP server: " SMTP_SERVER
read -p "Enter SMTP port: " SMTP_PORT

# Enter sender, recipient, and subject
read -p "Enter sender email: " SENDER
read -p "Enter recipient email: " RECIPIENT
read -p "Enter email subject: " SUBJECT

# Enter mail body
echo "Enter email body. Press Ctrl+D when done:"
BODY=$(cat)

# Convert newlines in BODY to Telnet-friendly format
BODY=$(echo "$BODY" | sed 's/$/\r/')

# Send email via telnet
{
    echo "EHLO localhost"
    echo "MAIL FROM:<$SENDER>"
    echo "RCPT TO:<$RECIPIENT>"
    echo "DATA"
    echo "Subject: $SUBJECT"
    echo "From: $SENDER"
    echo "To: $RECIPIENT"
    echo ""
    echo "$BODY"
    echo "."
    echo "QUIT"
} | nc "$SMTP_SERVER" "$SMTP_PORT"

echo "Email sent (or attempted) via Telnet."

