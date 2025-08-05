#!/bin/bash

### Various Voluptuous Variables ###
# Fax image directory
FAXDIR="/var/spool/asterisk/fax"
# SFTP Credentials
USER="user"
PASS="Password"
HOST="#.#.#.#"
PORT="22"
#KEY="/location/of/key/file/if/no/password"
# Local Log File
LOG_FILE="/var/log/Fax-to-SFTP-upload.log"
EMAIL_RECIPIENT="alerts@example.com"
RETRY_LIMIT=5
RETRY_DELAY=120  # seconds
### Various Voluptuous Variables Vacated ###

# Upload retry added to handle any connectivity issues.
main() {
    local file="$1"
    local filename="$(basename "$file")"

    for ((i=1; i<=RETRY_LIMIT; i++)); do
        echo "[$(date)] Attempt $i: Uploading $filename to $HOST" >> "$LOG_FILE"

    # Changed lftp to sftp w/sshpass & verbose debugging
        sshpass -p "$PASS" sftp  -oPort=$PORT "$USER@$HOST" <<EOF >> "$LOG_FILE" 2>&1
put "$file"
bye
EOF

        if [ $? -eq 0 ]; then
            echo "[$(date)] Upload succeeded: $filename" >> "$LOG_FILE"

    # Rudimentary file check using sshpass, sftp, ls, & awk. ## This would be much easier if I could just checksum the file on the remote server.
            RSIZE=$(sshpass -p "$PASS" sftp -oPort=$PORT "$USER@$HOST" <<EOF 2>/dev/null | awk '{print $5}'
ls -l "$filename"
EOF
)

            LSIZE=$(stat -c%s "$file")

            if [[ "$RSIZE" -eq "$LSIZE" ]]; then
                echo "[$(date)] Verified size match for $filename" >> "$LOG_FILE"
                echo -e "Fax upload successful: $filename\nSize: $LSIZE bytes\nTime: $(date)" | \
                    mailx -s "Fax Uploaded: $filename" -r "fax-alert@example.com" "$EMAIL_RECIPIENT"
                return 0
            else
                echo "[$(date)] Size mismatch for $filename (local: $LSIZE, remote: $RSIZE)" >> "$LOG_FILE"
            fi
        else
            echo "[$(date)] Upload failed for $filename (attempt $i)" >> "$LOG_FILE"
        fi

        sleep "$RETRY_DELAY"
    done

    echo "[$(date)] ERROR: Upload permanently failed after $RETRY_LIMIT attempts: $filename" >> "$LOG_FILE"
    echo -e "Fax upload FAILED: $filename\nAll $RETRY_LIMIT attempts failed.\nTime: $(date)" | \
        mailx -s "Fax Upload FAILED: $filename" -r "fax-alert@example.com" "$EMAIL_RECIPIENT"
    return 1
}

echo "[$(date)] Watching $FAXDIR for new files..." >> "$LOG_FILE"

# Monitor for new PDF files
inotifywait -m -e create --format '%f' "$FAXDIR" | while read NEWFILE; do
    [[ "$NEWFILE" != *.pdf ]] && {
        echo "[$(date)] Non-PDF fax file ignored: $NEWFILE" >> "$LOG_FILE"
        continue
    }

    UPLOAD="$FAXDIR/$NEWFILE"

    # Wait for file to finish writing
    PREVSIZE=0
    while true; do
        CURSIZE=$(stat -c%s "$UPLOAD" 2>/dev/null)
        if [[ "$CURSIZE" -eq "$PREVSIZE" && "$CURSIZE" -ne 0 ]]; then
            break
        fi
        PREVSIZE="$CURSIZE"
        sleep 5
    done

    echo "[$(date)] New fax PDF detected: $UPLOAD" >> "$LOG_FILE"

    # Upload with retry and email alert
    main "$UPLOAD" &
done
