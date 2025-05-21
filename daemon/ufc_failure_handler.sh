#!/bin/sh

# Universal Fan Controller (UFC) Service Failure Notification Handler
#
# DO NOT REMOVE LINE BELOW
# program_version="2.0"

# do nothing if email does not exist
[ -z "$email" ] && exit 255 # fail

# Use sendmail to send the email
sendmail -t <<EOF
To: $email
Subject: UFC Service Failure Notification

Universal Fan Controller (UFC) system service %i FAILED on $(hostname)

Related systemd daemon service status: $(systemctl status %i)

$([ -n "$log_filename" ] && printf "It is recommended that a system administrator check the corresponding UFC Service log for more details: %s\n" "$log_filename")
EOF
