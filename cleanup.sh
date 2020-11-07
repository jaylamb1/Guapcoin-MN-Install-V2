#!/bin/bash

#Cleanup the /home/guapadmin/MN_Report and /home/guapadmin/MN_Status dirs by deleting all but the last 10 files

/bin/rm -f $(/bin/ls -1t /home/guapadmin/MN_Status/ | /usr/bin/tail -n +11) 2>/dev/null

/bin/rm -f $(/bin/ls -1t /home/guapadmin/MN_Report/ | /usr/bin/tail -n +11) 2>/dev/null
