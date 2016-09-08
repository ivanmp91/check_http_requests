#!/usr/bin/perl -w

use warnings;
use strict;

use Getopt::Long;
use Time::Piece;
use Time::Seconds;
use Data::Dumper;

my $log;
my $time;
my $minutes;
my @requests = ();
my $params={};
my $header_count=40;

GetOptions($params,
   "log=s" =>\$log,
   "time=s" =>\$time,
   "minutes=s" =>\$minutes,
   "help",
  )
   or die usage();

checkArguments();

print "#" x $header_count . " REQUESTS PER MINUTE "."#" x $header_count ."\n";
for(my $i=0;$i<$minutes;$i++){
        my $request = '';
        my $count = 0;
        open my $FH,"<",$log or die "Cannot open log file";
        while(<$FH>){
                $request = $_;
                if ( $request =~ m/$time/ ) {
                        my $ip_addr = $1 if $request =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/;
                        my $date = $1 if $request =~ /(\[[\d]{2}\/.*\/[\d]{4}:[\d]{2}:[\d]{2}:[\d]{2}\ \+[\d]{4}\])/;
                        my $url = $1 if $request =~ /\"(.+?)\"/;
                        my $http_status = $1 if $request =~ /\"\s(\d{3})/;
                        push @requests, {ip => $ip_addr, status_code => $http_status, url => $url, date => $date};
                        $count+=1;
                }
        }
        close $FH;

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

print "\n";
print "#" x $header_count . " TOP 10 IPs "."#" x $header_count ."\n";
&showTop(\%ips);
print "\n";
print "#" x $header_count . " TOP 10 PAGES "."#" x $header_count ."\n";
&showTop(\%pages);
print "\n";
print "#" x $header_count . " PERCENTAGE OF SUCCESS & BAD RESPONSES "."#" x $header_count ."\n";
&showRequests(\%responses);
print "\n";
print "#" x $header_count . " TOP 5 PAGES PER IP "."#" x $header_count ."\n";
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
                --log           : Path to the access log file
                --time          : time start requests in access log format [DD/Mmm/YYYY:hh:mm ex: 22/Sep/2013:06:34]
                --minutes       : number of minutes after the time
                --help          : print this menu help
EOF
        exit 0;
}

# Get the TOP 5 of pages requested for the top 10 of IP's
sub getTopIpPages{
        my $ref = shift;
        my %ips = %$ref;
        my %ips_pages=();
        foreach my $request (@requests){
                my $ip = $request->{ip};
                my $url = $request->{url};
                next unless $ip;
                if(defined($ips_pages{$ip}{$url})){
                        $ips_pages{$ip}{$url} +=1;
                } else{
                        $ips_pages{$ip}{$url} = 1;
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
        foreach my $request (@requests){
                my $response = $request->{status_code};
                if($response =~ /2(.*)/){
                        $response_request{success} += 1;
                } elsif($response =~ /4(.*)/ || $response =~ /5(.*)/){
                        $response_request{failed} +=1;
                }
        }
        return %response_request;
}

# Count the number of requests made for each URL
sub getPageRequests {
        my %page_requests;
        foreach my $request (@requests){
                my $url = $request->{url};
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
        foreach my $request (@requests) {
                my $ip = $request->{ip};
                next unless $ip;
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