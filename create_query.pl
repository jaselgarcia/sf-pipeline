#!/usr/bin/env perl

use strict; use warnings;
use Net::Curl::Easy qw(:constants);
use JSON;
use constant {
	VERSION => "66.0",
	BASE_URL => "https://imrpj.my.salesforce.com"
};

my (
	$soql,
	$json_data,
	$curl,
	$response_body,
	$response_headers,
	$status_code,
	@headers,
	%options
);

sub usage {
	die "Usage: $0 <API Token> <file: SOQL Query>\n";
}

# Rudimentary error checking
usage unless (
	scalar @ARGV == 2 && 
	-f $ARGV[1]
);

@headers = (
	"Authorization: Bearer $ARGV[0]",
	"Accept: application/json",
	"Content-type: application/json",
);

# Prepare SOQL file for JSON string
open my $fh, '<', $ARGV[1] or die $!;
while (<$fh>) {
	chomp $_;
	$_ =~ s/^\s+$//;
	$_ =~ s/^\s+/ /;
	$_ =~ s/(,)\s+$/$1/;
	$_ =~ s/(SELECT)\s+/$1/i;
	$soql .= $_;
}

$json_data = encode_json({
	operation => "query",
	query => $soql
});

# Comma notation required to maintain module constants
%options = (
	CURLOPT_URL, "${\BASE_URL}/services/data/v${\VERSION}/jobs/query",
	CURLOPT_POST, 1,
	CURLOPT_HTTPHEADER,  \@headers,
	CURLOPT_POSTFIELDS, $json_data,
	CURLOPT_WRITEDATA, \$response_body,
	CURLOPT_HEADERDATA, \$response_headers
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
	$status_code = $curl->getinfo( CURLINFO_HTTP_CODE ); 
	if ($status_code >= 200 && $status_code < 300) {
		printf "%s", decode_json($response_body)->{id};
		exit 0;
	} else {
		die "$response_body\n";
	}
}
