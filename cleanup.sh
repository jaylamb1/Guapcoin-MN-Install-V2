#!/bin/bash

#Cleanup the /home/guapadmin/MN_Report and /home/guapadmin/MN_Status dirs by deleting all but the last 10 files

find /home/guapadmin/MN_Status -type f -mtime +9 -exec rm -f {} \; 2>/dev/null

find /home/guapadmin/MN_Report -type f -mtime +9 -exec rm -f {} \; 2>/dev/null
