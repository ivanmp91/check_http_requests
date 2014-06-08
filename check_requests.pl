#!/usr/bin/perl -w

use warnings;
use strict;

use Getopt::Long;
use Time::Piece;
use Time::Seconds;

my $log;
my $time;
my $minutes;
my @requests;
my $params={};

GetOptions($params,
   "log=s" =>\$log,
   "time=s" =>\$time,
   "minutes=s" =>\$minutes,
   "help",
  )
   or die usage();

checkArguments();

for(my $i=0;$i<$minutes;$i++){
	my $request = '';
	open my $FH,"<",$log or die "Cannot open log file";
	while(<$FH>){
		if ( $_ =~ m/$time/ ) {
			$request .= $_;
		}
	}
	close $FH;
	my $count = scalar split /\n/,$request;
	push(@requests, $request) if $request ne '';
	print $time." number of requests: ".$count."\n";
	my $t = Time::Piece->strptime($time, "%d/%b/%Y:%H:%M");
	$t+=ONE_MINUTE;
	$time= $t->strftime("%d/%b/%Y:%H:%M");
}

my %ips = &getIpRequests;
my $top_ips = &getTop(\%ips);
my %pages = &getPageRequests;
my %responses = &getRequestResponses;
my %pages_ip = &getTopIpPages($top_ips);

print "###################### TOP 10 IP's ######################\n";
&showTop(\%ips);
print "##################### TOP 10 PAGES ######################\n";
&showTop(\%pages);
print "##################### PERCENTAGE OF SUCCESS & BAD RESPONSES ######################\n";
&showRequests(\%responses);
print "##################### TOP 5 PAGES PER IP ######################\n";
&showTopIpPages(\%pages_ip);

# Check all mandatory arguments are initialized
sub checkArguments{
        if(defined($params->{help})){
                usage();
        } elsif(!defined($log) ||  !defined($time) || !defined($minutes)){
		usage("Not initialized all the mandatory arguments");
        }
}

# Show usage menu options
sub usage{
   print shift()."\n";
   print <<EOF;
        Usage: check_requests.pl [OPTIONS]
        Check Number of requests from access log file apache
        Mandatory arguments:
                --log		: Path to the access log file
                --time  	: time start requests in access log format [DD/Mmm/YYYY:hh:mm ex: 22/Sep/2013:06:34]
		--minutes 	: number of minutes after the time
                --help     	: print this menu help
EOF
        exit 0;
}

# Get the TOP 5 of pages requested for the top 10 of IP's
sub getTopIpPages{
	my $ref = shift;
	my %ips = %$ref;
	my %ips_pages=();
	foreach my $line (@requests){
		my @fields = split(' ',$line);
		my $ip = $fields[0];
		if(defined($ips{$ip})){
			my $url = $fields[6];
			if(defined($ips_pages{$ip}{$url})){
				$ips_pages{$ip}{$url} +=1;	
			} else{
				$ips_pages{$ip}{$url} = 1;
			}
		}
	}
	return %ips_pages;
}

# Count the number of failed and success responses
sub getRequestResponses{
	my %response_request = (
		success => 0,
		failed => 0
	);
	foreach my $line (@requests){
		my @fields = split(' ',$line);
		my $response = $fields[8];
		if($response =~ /2(.*)/){
			$response_request{success} += 1;
		} elsif($response =~ /4(.*)/){
			$response_request{failed} +=1;
		}
	}
	return %response_request;
}

# Count the number of requests made for each URL
sub getPageRequests {
	my %page_requests;
	foreach my $line (@requests){
		my @fields = split(' ',$line);
		my $url = $fields[6];
		if(! defined($page_requests{$url})){
			$page_requests{$url} = 1;
		} else{
			$page_requests{$url} +=1;
		}
	}
	return %page_requests;
}

# Count the number of requests made for an IP
sub getIpRequests {
	my %ip_requests;
	foreach my $line (@requests) {
		my @fields = split(' ',$line);
		my $ip = $fields[0];
		if(!defined($ip_requests{$ip})){
			$ip_requests{$ip} = 1;	
		} else{
			$ip_requests{$ip}+=1;
		}
	}
	return %ip_requests;
}

# Get the top 10 for a given hash
sub getTop{
	my $ref = shift;
	my %hash = %$ref;
	my %sorted_hash=();
	my $count = 0;
	foreach my $key (sort({$hash{$b} <=> $hash{$a}} keys %hash)) {
		$sorted_hash{$key} = $hash{$key};
		$count +=1;
		last if $count > 9;
	}
	return \%sorted_hash;
}

# Show top 10 of pages requested per IP and make a descending order by the number of requests
sub showTopIpPages{
        my $ref = shift;
        my %pages_ip = %$ref;
        my $count;
        foreach my $ip (sort {$pages_ip{$b} <=> $pages_ip{$a}} keys %pages_ip ){
                $count = 0;
                print "$ip : \n";
                foreach my $url (sort{$pages_ip{$ip}{$b} <=> $pages_ip{$ip}{$a} } keys %{$pages_ip{$ip}}){
                        print "$url : $pages_ip{$ip}{$url}\n";
                        $count +=1;
                        last if $count > 4;
                }
        }
}

# Show top 10 for a given hash and make a descending order by the value
sub showTop{
	my $ref = shift;
	my $sort_ref = &getTop($ref);
	my %sorted_requests = %$sort_ref;
	foreach my $key (sort {$sorted_requests{$b} <=> $sorted_requests{$a}}keys %sorted_requests ) {
		print "$key : $sorted_requests{$key}\n";
	}
}

# Show the percentages of failed and success requests
sub showRequests{
	my $ref = shift;
	my $total = $ref->{success} + $ref->{failed};
	my $success = ($ref->{success} * 100)/$total if $total>0;
	my $failed = ($ref->{failed} * 100)/$total if $total>0;
	print "Success: $success %\n" if defined $success;
	print "Fails: $failed %\n" if defined $failed;
}
