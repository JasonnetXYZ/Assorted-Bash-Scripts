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
LOG_FILE="/var/log/SFTP-upload.log"
### Various Voluptuous Variables Vacated ###

echo "[$(date)] Watching $FAXDIR for new files..." >> "$LOG_FILE"

inotifywait -m -e create --format '%f' "$FAXDIR" | while read NEWFILE; do
    # Check if the new file is a PDF
    if [[ "$NEWFILE" != *.pdf ]]; then
        echo "[$(date)] Non-PDF fax file ignored: $NEWFILE" >> "$LOG_FILE"
        continue
    fi

    UPLOAD="$FAXDIR/$NEWFILE"

        # Wait for the file to be fully written
    PREVSIZE=0
    while true; do
        CURSIZE=$(stat -c%s "$UPLOAD" 2>/dev/null)
        if [[ "$CURSIZE" -eq "$PREVSIZE" && "$CURSIZE" -ne 0 ]]; then
            break
        fi
	PREVSIZE="$CURSIZE"
        sleep 5
    done

    echo "[$(date)] New fax PDF uploaded: $UPLOAD" >> "$LOG_FILE"

    # Changed lftp to sftp w/sshpass & verbose debugging
    sshpass -p "$PASS" sftp -v -oPort=$PORT "$USER@$HOST" <<EOF >> "$LOG_FILE" 2>&1
put "$UPLOAD"
bye
EOF

    if [ $? -eq 0 ]; then
        echo "[$(date)] Uploaded $NEWFILE to $HOST" >> "$LOG_FILE"
        
    else
        echo "[$(date)] Failed to upload $NEWFILE" >> "$LOG_FILE"
    fi

   # Rudimentary file check using sshpass, sftp, ls, & awk. ## This would be much easier if I could just checksum the file on the remote server. 
RSIZE=$(sshpass -p "$PASS" sftp -oPort=$PORT "$USER@$HOST" <<EOF | awk -v file="$NEWFILE" '$NF == file { print $5 }'
ls -l
bye
EOF
)

    LSIZE=$(stat -c%s "$UPLOAD")

    if [[ "$LSIZE" -eq "$RSIZE" ]]; then
        echo "[$(date)] Verified: $NEWFILE upload successful (size match: $LSIZE bytes)" >> "$LOG_FILE"
    else
        echo "[$(date)] WARNING: Size mismatch for $NEWFILE! Local: $LSIZE, Remote: $RSIZE" >> "$LOG_FILE"
        
        # Send email alert
        echo -e "Subject: SFTP Upload Mismatch Alert\n\nFile: $NEWFILE\nLocal Size: $LSIZE\nRemote Size: $RSIZE\nTime: $(date)" | \
    mailx -s "SFTP Upload Mismatch: $NEWFILE" -r "from-email@example.com" to-email@example.com
    fi    

done


