#!/usr/bin/env perl

# print a quick summary of the number of rewards to each country
use strict;
use warnings;

use Text::CSV; # sudo apt-get install libtext-csv-perl

my $csv = Text::CSV->new({ binary => 1 });

my %list;

for my $file (@ARGV) {
    print "File $file\n";
    open(my $fh, "<", $file) or die "$!";
    my $header = $csv->getline($fh);

    while (my $row = $csv->getline($fh)) {
        my $country = $row->[21];

        next unless $country;

        print "Country: $country\n";
        $list{$country}++;
    }
}

for my $country (sort keys(%list)) {
    printf " %4d: ", $list{$country};
    print "$country\n";
}

