check_requests
==============
Script to count the number of requests per minute.

Usage: check_requests.pl [OPTIONS]
          Check Number of requests from access log file apache
          Mandatory arguments:
                  --file : file name to check
                  --time  : time start requests in apache log format [DD/Mmm/YYYY:hh:mm ex: 22/Sep/2013:06:34]
                  --minutes : number of minutes after the time
                  --help     : print this menu help
Example use:

./check_requests.pl --file access_log --time 07/Oct/2013:22:09 --minutes 2

This example will count all the requests from 22:09 h. until 22:10 h. From the apache access log file.

Author: ivan@opentodo.net
