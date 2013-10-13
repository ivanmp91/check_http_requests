#!/usr/bin/perl -w

use warnings;
use strict;

use Getopt::Long;
use Time::Piece;
use Time::Seconds;
my $logdir="/var/log/apache2/";
my $log;
my $file;
my $time;
my $minutes;
my $requests;
my $params={};



GetOptions($params,
   "file=s" =>\$file,
   "time=s" =>\$time,
   "minutes=s" =>\$minutes,
   "help",
  )
   or die usage();

checkArguments();

sub checkArguments{
        if(defined($params->{help})){
                usage();
        }
        else{
                if(defined($file) && defined($time) && defined($minutes)){
			$log=$logdir.$file;
			my $requests;
			for(my $i=0;$i<$minutes;$i++){
				$requests=`grep $time $log | wc -l`;
				print $time." number of requests: ".$requests."\n";
				my $t = Time::Piece->strptime($time, "%d/%b/%Y:%H:%M");
				$t+=ONE_MINUTE;
				$time= $t->strftime("%d/%b/%Y:%H:%M");
			}
                }
                else{
                        usage("Not initialized all the mandatory arguments");
                }
        }
}

sub usage{
   print shift()."\n";
   print <<EOF;
        Usage: check_requests.pl [OPTIONS]
        Check Number of requests from access log file apache
        Mandatory arguments:
                --file : file name to check
                --time  : time start requests in apache log format [DD/Mmm/YYYY:hh:mm ex: 22/Sep/2013:06:34]
		--minutes : number of minutes after the time
                --help     : print this menu help
EOF
        exit 0;
}

