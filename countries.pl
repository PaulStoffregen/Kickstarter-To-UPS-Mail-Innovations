#! /usr/bin/perl

# print a quick summary of the number of rewards to each country

use Text::CSV;   # sudo apt-get install libtext-csv-perl

my $csv = Text::CSV->new ({ binary => 1 });

foreach $file (@ARGV) {
	print "File $file\n";
	open $fh, "<", $file or die "$!";
		$header = $csv->getline($fh);
		while ($row = $csv->getline($fh)) {
			$country = $row->[21];
			print "Country: $country\n";
			if ($country) {
				$list{$country}++;
			}
		}
	close $fh;
}

foreach $country (sort keys(%list)) {
	printf " %4d: ", $list{$country};
	print "$country\n";


}

