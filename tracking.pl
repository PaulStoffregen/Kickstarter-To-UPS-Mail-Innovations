#! /usr/bin/perl

# run this on the .Out files written by UPS Worldship
# it prints a nice list which allows for easily marking
# the rewards as shipped, with the tracking number.

foreach $file (@ARGV) {
	#print "File $file\n";
	open $fh, "<", $file or die "$!";
	undef $reference;
	undef $tracking;
	undef $name;
	while (<$fh>) {
		if (/<Reference1>([A-Z][0-9]{4})<\/Reference1>/) {
			$reference = $1;
			#print "ref: $reference\n";
		}
		if (/<CompanyOrName>([^<]+)<\/CompanyOrName>/) {
			$name = $1;
			#print "name: $name\n";
		}
		if (/<MailManifestId>([0-9]+)<\/MailManifestId>/) {
			$tracking = $1;
			#print "track: $tracking\n";
		}
	}
	close $fh;
	if ($reference && $tracking && $name) {
		print $reference, "  ", $tracking, "  ", $name, "\n";
	}
}

foreach $country (sort keys(%list)) {
	printf " %4d: ", $list{$country};
	print "$country\n";


}

