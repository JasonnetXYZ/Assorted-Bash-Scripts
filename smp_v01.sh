#!/bin/bash

# Variables for email, drive detection, and test intervals. 
EMAIL="jason@worldspice.net"
SUBJECT_PASS="All Drives Passed - All Is Well!"
SUBJECT_FAIL="Failure Detected - Check Drive Results!"
RESULT_FILE="/tmp/smp_results.txt"
DRIVES=($(lsblk -dno NAME | grep -E '^(sd|nvme)'))  # List SATA and NVME drives
SHORT_TEST=120 # In seconds
LONG_TEST=7200 # In seconds

# Begin the results file
echo "SMART Test Results - $(date)" > "$RESULT_FILE"

# SMART Test Function
run_smart_test() {
    local drive=$1
    local test_type=$2
    
    # Start testing
    echo "Starting $test_type test on /dev/$drive..."
    smartctl -t "$test_type" /dev/"$drive" &>> "$RESULT_FILE"
}

# Run SMART tests on all drives
for drive in "${DRIVES[@]}"; do
    echo "Processing /dev/$drive..." >> "$RESULT_FILE"

    # Run short test
    run_smart_test "$drive" short

    # Wait for the short test to complete 
    sleep $SHORT_TEST

    # Run long test
    run_smart_test "$drive" long

    # Wait for the long test to complete 
    sleep $LONG_TEST

    # Collect SMART status
    echo "SMART status for /dev/$drive:" >> "$RESULT_FILE"
    smartctl -H /dev/"$drive" >> "$RESULT_FILE"
    smartctl -A /dev/"$drive" >> "$RESULT_FILE"
    echo -e "\n-----------------------------\n" >> "$RESULT_FILE"
done

# Check for issues in the results
if grep -qE "FAILED|Pre-fail|error|critical" "$RESULT_FILE"; then
    SUBJECT="$SUBJECT_FAIL"
else
    SUBJECT="$SUBJECT_PASS"
fi

# Send the email
mailx -s "$SUBJECT" "$EMAIL" < "$RESULT_FILE"

# Cleanup
rm -f "$RESULT_FILE"

exit 0
