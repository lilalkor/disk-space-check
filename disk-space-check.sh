#!/bin/bash

# Some variables
# E-mail for recieving alerts
# EMAIL="user@domain.com test@domain.com"
EMAIL=""
# Name of this server - just to make it different from other e-mails, not really needed
# SERVER="server1.domain.com"
SERVER=""
# E-mail used to send alerts. Use address, which is allowed do send mail from your server (remember about SPF and other things)
FROM=""
# Send alert only when usage is higher, then LIMIT in percent
LIMIT=85

# Some constants
ANTISPAM_FILE="/tmp/disk_checker_mail_sent"
MSG="/tmp/disk_usage.txt"

# Get info about disk usage
INFO=`df -lh --sync --output=size,used,avail,pcent  / | grep G`
# And put it into variables
SIZE=`echo $INFO | awk '{print $1}'`
USED=`echo $INFO | awk '{print $2}'`
FREE=`echo $INFO | awk '{print $3}'`
PCNT=`echo $INFO | awk '{print $4}'`

if [ ${PCNT%?} -ge $LIMIT ]; then
	# Create message
	echo -e "WARNING! High disk usage!" > $MSG
	echo -e "Total: $SIZE" >> $MSG
	echo -e "Used: $USED ($PCNT)" >> $MSG
	echo -e "Free: $FREE" >> $MSG
	echo -e "======" >> $MSG
	echo -e "Most space (in MB) used by:" >> $MSG
	# Very custom
	du -xmst 500M --exclude=/mnt/* /*/* 2>/dev/null | sort -rnk1 >> $MSG
	# Send e-mail
	if [ ! -f $ANTISPAM_FILE ]; then
		for RCPT in $EMAIL; do
			mail -r $FROM -s "$(echo -e "High disk usage on $SERVER!\nFrom: $SERVER <${FROM}>\nReply-to: ${FROM}\n")" $RCPT < $MSG
		done
		touch $ANTISPAM_FILE
		rm $MSG
	else
		find $ANTISPAM_FILE -mtime +1 -delete
	fi
fi
