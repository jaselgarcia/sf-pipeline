#!/usr/bin/env perl

use strict; use warnings;
use Net::Curl::Easy qw(:constants);
use Data::Dumper;
use JSON;
use constant {
	VERSION => "66.0",
	BASE_URL => "https://imrpj.my.salesforce.com"
};

my (
	$curl,
	$response_body,
	$response_headers,
	$http_response,
	@headers,
	%options,
	$locator,
	$full_response
);

sub usage {
	die "usage: $0 <API Token> <str: Job Id>\n";
}

sub return_locator {
	# Capture errors in $@
	eval { $curl->perform() };
	die "Request error: $@\n" if $@;

	my $http_response = $curl->getinfo( CURLINFO_HTTP_CODE ); 

	if ($http_response >= 200 && $http_response < 300) {
		my ($locator) = $response_headers =~ m/sforce-locator: ([^ \n]+)/;
		$locator =~ s/\r//g;
		return "$locator\n";
	}
}

# Rudimentary error checking
usage unless scalar @ARGV == 2;

@headers = (
	"Authorization: Bearer $ARGV[0]",
	"Accept-Encoding: gzip"
);

# Comma notation required to maintain module constants
%options = (
	CURLOPT_URL, "${\BASE_URL}/services/data/v${\VERSION}/jobs/query/$ARGV[1]/results", 
	CURLOPT_HTTPHEADER,  \@headers,
	CURLOPT_WRITEDATA, \$response_body,
	CURLOPT_HEADERDATA, \$response_headers,
	CURLOPT_ACCEPT_ENCODING, "gzip"
);

$curl = Net::Curl::Easy->new();

while (my ($key, $value) = each (%options)) {
	$curl->setopt( $key, $value );
}

while ( chomp($locator = return_locator) ) { 
	$full_response .= $response_body;
	last if $locator eq "null";

	# Refactor to one line?
	if ($options{${\CURLOPT_URL}} =~ /[?&]locator=.+$/ ) {
		$options{${\CURLOPT_URL}} =~ s/locator=[^&]+/locator=$locator/;
	} else {
		my $delim = $options{${\CURLOPT_URL}} =~ /\?/ ? "&" : "?";
		$options{${\CURLOPT_URL}} .= "${delim}locator=$locator";
	}

	# Open up response variables for reassignment
	undef $response_headers;
	undef $response_body;

	# Re-initialize request
	while (my ($key, $value) = each (%options)) {
		$curl->setopt( $key, $value );
	}
}

print "$full_response";
