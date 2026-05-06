#!/usr/bin/env perl
# TODO: add custom delimiter flag. Currently defaults to comma.

use strict; use warnings;
use open qw( :std :encoding(utf-8) );
use Text::CSV;
use Data::Dumper;

sub usage {
	die "$0: need file to search and field to return as arguments.\n"
}

# Die without stdin
die "Need to parse from stdin.\n" if -t STDIN;

# TODO: ensure first argument is file and second is integer
usage unless scalar @ARGV == 2;

# Read lookup file into hash
# TODO: utilize csv mthods to parse lookup file
my $lookup_hash;
open(my $fh, '<', $ARGV[0]) or die "Could not read '$ARGV[0]': $!\n";
chomp(my @lines	= <$fh>);
foreach my $line (@lines) {
	my ($key, @arr) = split /,/, $line;
	$lookup_hash->{$key} = \@arr;
}

my $csv = Text::CSV->new({binary=>1, keep_meta_info=>1});
my $line_no = 1;

# TODO: check if field exists
my $return_idx = $ARGV[1] - 1;

my %email_map = (
	personal => 9,
	alternate => 10,
	work => 11,
	other_1 => 13,
	other_2 => 14,
	other_3 => 15,
	other_4 => 16
);

while (<stdin>) {
	chomp(my $line = $_);

	my %emails;
	my @freq;
	
	# Standard error checking, reused from vstack. Can probably be improved
	my ($err_code, $err_str, $err_pos) = $csv->error_diag() if !$csv->parse($line);
	$csv->parse($line) or die "Encountered error on line $line_no of STDIN:\t<$line>\n$err_code\t$err_str\t$err_pos\n";
	
	my @all_fields = $csv->fields();

	# Populate email hash with each email field
	while (my($key, $idx) = each(%email_map)) {
		$emails{$key} = $all_fields[$idx] unless $all_fields[$idx] eq "";
	}

	foreach my $email (values %emails) {
		my $count = $lookup_hash->{$email}[$return_idx] if exists $lookup_hash->{$email}[$return_idx];
		push @freq, $count if defined $count;
		# warn "\t$email -> $count\n";
	}

	@freq = sort {$b <=> $a} @freq;
	my $max = shift @freq unless $#freq < 0;

	for (my $i = 0; $i < scalar(@all_fields); $i++) {
		$all_fields[$i] = "\"$all_fields[$i]\"" if $csv->is_quoted($i);	
		print "$all_fields[$i],";
		# warn "Printing field $i - $all_fields[$i],\n";
	}

	print $max ? "$max\n" : "0\n";

	$line_no++;
}
