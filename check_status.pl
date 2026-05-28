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
	@job_status
);

sub usage {
	die "Usage: $0 <API Token> <str: Job Id>\n";
}

# Rudimentary error checking
usage unless scalar @ARGV == 2;

@headers = (
	"Authorization: Bearer $ARGV[0]",
);

# Comma notation required to maintain module constants
%options = (
	CURLOPT_URL, "${\BASE_URL}/services/data/v${\VERSION}/jobs/query/$ARGV[1]",
	CURLOPT_HTTPHEADER,  \@headers,
	CURLOPT_WRITEDATA, \$response_body,
	CURLOPT_HEADERDATA, \$response_headers
);

@job_status = qw(
	JobComplete
	InProgress
	UploadComplete
	Aborted
	Failed
);

$curl = Net::Curl::Easy->new();

while (my ($key, $value) = each (%options)) {
	$curl->setopt( $key, $value );
}

# Capture errors in $@
eval { 
	$curl->perform()
};

# Return job id upon successful curl
if ($@) {
	die "Request error: $@\n";
} else {
	$http_response = $curl->getinfo( CURLINFO_HTTP_CODE ); 
	if ($http_response >= 200 && $http_response < 300) {
		printf "%s\n", decode_json($response_body)->{object};
		for (my $i = 0; $i < scalar @job_status; $i++) { 
			exit $i if decode_json($response_body)->{state} eq $job_status[$i];
		}
	} else {
		die "$response_body\n";
	}
}
