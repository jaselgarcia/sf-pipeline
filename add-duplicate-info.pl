#!/usr/bin/env perl

use strict; use warnings;
use open qw( :std :encoding(utf-8) );
use Text::CSV;

# Currently a quick one-off script though may refactor to make a more generally useful script.
# I specifically needed a quick and dirty script that would grep a file and return a max value.

my $csv = Text::CSV->new({binary=>1, keep_meta_info=>1});
my $line_no = 1;
my $grep = "/home/jasel/01_Data/02_Salesforce/duplicate-count.csv";

while (<stdin>) {
	chomp(my $line = $_);

	my %emails;
	my @freq;
	
	# Standard error checking, reused from vstack. Can probably be improved
	my ($err_code, $err_str, $err_pos) = $csv->error_diag() if !$csv->parse($line);
	$csv->parse($line) or die "Encountered error on line $line_no of STDIN:\t<$line>\n$err_code\t$err_str\t$err_pos\n";
	
	my @all_fields = $csv->fields();
	# warn "$line\n";
	# warn scalar($csv->fields()) . "\n";
	# warn @all_fields . "\n";

	# Populate email hash with each email field
	# Very verbose code currently. Need to refactor
	$emails{"personal"} = $all_fields[3] unless $all_fields[3] eq "";
	$emails{"alternate"} = $all_fields[4] unless $all_fields[4] eq "";
	$emails{"work"} = $all_fields[5] unless $all_fields[5] eq "";
	$emails{"other_1"} = $all_fields[6] unless $all_fields[6] eq "";
	$emails{"other_2"} = $all_fields[7] unless $all_fields[7] eq "";
	$emails{"other_3"} = $all_fields[8] unless $all_fields[8] eq "";

	# Need to refactor hardcoded filenames etc.
	# warn "Grepping through $line_no\n";
	foreach my $email (values %emails) {
		$email =~ s/\\/\\\\\\\\/g;
		$email =~ s/\./\\./g;
		$email =~ s/\*/\\*/g;
		chomp (my $count = `grep ",$email\$" $grep | cut -d , -f 1`);
		push @freq, $count;
		# warn "\t$email -> $count\n";
	}

	@freq = sort {$b <=> $a} @freq;
	my $max = shift @freq unless $#freq < 0;

	# warn "\t\tMax: $max\n" if defined $max;

	for (my $i = 0; $i < scalar(@all_fields); $i++) {
		$all_fields[$i] = "\"$all_fields[$i]\"" if $csv->is_quoted($i);	
		print "$all_fields[$i],";
		# warn "Printing field $i - $all_fields[$i],\n";
	}

	# warn $max ? "$max\n" : "0\n";
	print $max ? "$max\n" : "0\n";


	$line_no++;
	
}
