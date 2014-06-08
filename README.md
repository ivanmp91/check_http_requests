check_requests
==============
Script to count the number of requests per minute for a given time and shows the next reports for the time period:

	- Show top 10 of IP's.

	- Show top 10 of pages requested.

	- Show percentage of success and bad responses.

	- Show top 5 pages requested per source IP.

Usage: check_requests.pl [OPTIONS]
Mandatory arguments:

	--log		: Path to the access log file
	--time  	: time start requests in access log format [DD/Mmm/YYYY:hh:mm ex: 22/Sep/2013:06:34]
	--minutes 	: number of minutes after the time
	--help     	: print this menu help

Example use:

./check_requests.pl --log /var/log/apache2/access_log --time 07/Oct/2013:22:09 --minutes 2

This example will count all the requests from 22:09 h. until 22:10 h. From the apache access log file and show the reports for this time period.

Author: ivan@opentodo.net
