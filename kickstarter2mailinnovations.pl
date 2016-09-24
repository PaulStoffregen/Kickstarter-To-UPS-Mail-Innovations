#! /usr/bin/perl

# convert a Kickstarter CSV file to many UPS Worldship XML files
# for use with the "XML Auto Import" feature.

use Text::CSV;   # sudo apt-get install libtext-csv-perl
use XML::LibXML; # sudo apt-get install libxml-libxml-perl

my $csv = Text::CSV->new ({ binary => 1 });

(exists $ARGV[0] && $ARGV[0] =~ /\.csv$/ &&
 exists $ARGV[1] && $ARGV[1] =~ /^([a-zA-Z])\.txt$/) 
	or die "usage: kickstarter2mailinnovations.pl file.cvs N.txt\n";
$reward = uc($1);
-r $ARGV[0] or die "Unable to read \"$ARGV[0]\"\n";
-r $ARGV[1] or die "Unable to read \"$ARGV[1]\"\n";


open $fh, "<", $ARGV[1] or die "$!";
$numitems = 0;
$total = 0;
while (<$fh>) {
	#print "Item: $_\n";
	($qty[$numitems], $item[$numitems], $price[$numitems]) = split;
	$total += $price[$numitems] * $qty[$numitems];
	$numitems++;
	#@list = split;
	#print "Item: $list[0] ", join(", ", @list), "\n";
}
close $fh;


print "total:  $total\n";
print "Reward: $reward\n";
print "File: $ARGV[0]\n";

open $fh, "<", $ARGV[0] or die "$!";
#open $fh, "<:encoding(utf8)", $ARGV[0] or die "$!";
open $fref, ">>", "allrefnums.txt" or die "$!";

$header = $csv->getline($fh);
#print  $header->[24], "\n";

while ($row = $csv->getline($fh)) {
	$toolong = 0;
	$name = $row->[15];
	$addr1 = $row->[16];
	$addr2 = $row->[17];
	$city = $row->[18];
	$state = $row->[19];
	$postalcode = $row->[20];
	$country = $row->[21];
	$phone = $row->[23];
	next unless $country;

	$refnum = $reward . sprintf("%04d", $row->[0]);
	print $fref "$refnum\n";

	next if $country eq "United States";
	if ($country eq "Brunei Darussalam") {
		$country = "Brunei";
	} elsif ($country eq "China") {
		$country = "China, People's Republic of";
	} elsif ($country eq "Korea, Republic of") {
		$country = "Korea, South";
	} elsif ($country eq "Russian Federation") {
		$country = "Russia";
	}

	if (length($name) > 35 || length($addr1) > 35 || length($addr2) > 35
	  || length($city) > 30 || length($postalcode) > 35 || length($phone) > 15) {
		$toolong = 1;
	}

	$all = $name . $addr1 . $addr2 . $city . $state . $postalcode . $country . $phone;
	if ($all =~ /[\x{100}-\x{FFFF}]/) {
		$specialchars = 2;
	} elsif ($all =~ /[\x{80}-\x{FF}]/) {
		$specialchars = 1;
	} else {
		$specialchars = 0;
	}

	print "Ref #:   ", $refnum, ",  ";
	print "Backer:  ", $row->[2], "\n";

	$doc = XML::LibXML::Document->new("1.0", "UTF-8");

	$OpenShipments = $doc->createElement("OpenShipments");
	$doc->setDocumentElement($OpenShipments);
	$OpenShipments->setAttribute("xmlns" => "x-schema:OpenShipments.xdr");

	$OpenShipment = $doc->createElement("OpenShipment");
	$OpenShipments->appendChild($OpenShipment);
	$OpenShipment->setAttribute("ShipmentOption" => "SP");
	$OpenShipment->setAttribute("ProcessStatus" => "");

	$ShipTo = $doc->createElement("ShipTo");
	$OpenShipment->appendChild($ShipTo);

	$CompanyOrName = $doc->createElement("CompanyOrName");
	$CompanyOrName->appendTextNode($name);
	$ShipTo->appendChild($CompanyOrName);
	$Attention = $doc->createElement("Attention");
	$Attention->appendTextNode($name);
	$ShipTo->appendChild($Attention);
	$Address1 = $doc->createElement("Address1");
	$Address1->appendTextNode($addr1);
	$ShipTo->appendChild($Address1);
	if ($addr2) {
		$Address2 = $doc->createElement("Address2");
		$Address2->appendTextNode($addr2);
		$ShipTo->appendChild($Address2);
	}
	$CountryTerritory = $doc->createElement("CountryTerritory");
	$CountryTerritory->appendTextNode($country);
	$ShipTo->appendChild($CountryTerritory);
	$PostalCode = $doc->createElement("PostalCode");
	$PostalCode->appendTextNode($postalcode);
	$ShipTo->appendChild($PostalCode);
	$CityOrTown = $doc->createElement("CityOrTown");
	$CityOrTown->appendTextNode($city);
	$ShipTo->appendChild($CityOrTown);
	$StateProvinceCounty = $doc->createElement("StateProvinceCounty");
	$StateProvinceCounty->appendTextNode($state);
	$ShipTo->appendChild($StateProvinceCounty);
	$Telephone = $doc->createElement("Telephone");
	$Telephone->appendTextNode($phone);
	$ShipTo->appendChild($Telephone);

	$ShipmentInformation = $doc->createElement("ShipmentInformation");
	$OpenShipment->appendChild($ShipmentInformation);
	$ServiceType = $doc->createElement("ServiceType");
	$ServiceType->appendTextNode("MIP");
	$ShipmentInformation->appendChild($ServiceType);
	$PackageType = $doc->createElement("PackageType");
	$PackageType->appendTextNode("Parcels");
	$ShipmentInformation->appendChild($PackageType);
	$NumberOfPackages = $doc->createElement("NumberOfPackages");
	$NumberOfPackages->appendTextNode("1");
	$ShipmentInformation->appendChild($NumberOfPackages);
	$ShipmentActualWeight = $doc->createElement("ShipmentActualWeight");
	$ShipmentActualWeight->appendTextNode("0.1");
	$ShipmentInformation->appendChild($ShipmentActualWeight);
	$DescriptionOfGoods = $doc->createElement("DescriptionOfGoods");
	$DescriptionOfGoods->appendTextNode("Electronic Parts");
	$ShipmentInformation->appendChild($DescriptionOfGoods);
	$Reference1 = $doc->createElement("Reference1");
	$Reference1->appendTextNode($refnum);
	$ShipmentInformation->appendChild($Reference1);
	$Reference2 = $doc->createElement("Reference2");
	$Reference2->appendTextNode("KS");
	$ShipmentInformation->appendChild($Reference2);
	$BillTransportationTo = $doc->createElement("BillTransportationTo");
	$BillTransportationTo->appendTextNode("Shipper");
	$ShipmentInformation->appendChild($BillTransportationTo);
	$BillDutyTaxTo = $doc->createElement("BillDutyTaxTo");
	$BillDutyTaxTo->appendTextNode("Receiver");
	$ShipmentInformation->appendChild($BillDutyTaxTo);

	$InternationalDocumentation = $doc->createElement("InternationalDocumentation");
	$OpenShipment->appendChild($InternationalDocumentation);
	$CustomsValueTotal = $doc->createElement("CustomsValueTotal");
	$CustomsValueTotal->appendTextNode(sprintf("%.2f", $total));
	$InternationalDocumentation->appendChild($CustomsValueTotal);
	$CustomsValueCurrencyCode = $doc->createElement("CustomsValueCurrencyCode");
	$CustomsValueCurrencyCode->appendTextNode("USD");
	$InternationalDocumentation->appendChild($CustomsValueCurrencyCode);
	$InvoiceCurrencyCode = $doc->createElement("InvoiceCurrencyCode");
	$InvoiceCurrencyCode->appendTextNode("US");
	$InternationalDocumentation->appendChild($InvoiceCurrencyCode);
	$CN22GoodsType = $doc->createElement("CN22GoodsType");
	$CN22GoodsType->appendTextNode("4");
	$InternationalDocumentation->appendChild($CN22GoodsType);
	$CN22GoodsTypeOtherDescription = $doc->createElement("CN22GoodsTypeOtherDescription");
	$CN22GoodsTypeOtherDescription->appendTextNode("Electronic Parts");
	$InternationalDocumentation->appendChild($CN22GoodsTypeOtherDescription);

	for ($i=0; $i < $numitems; $i++) {
		$Goods = $doc->createElement("Goods");
		$OpenShipment->appendChild($Goods);
		$PartNumber = $doc->createElement("PartNumber");
		$PartNumber->appendTextNode($item[$i]);
		$Goods->appendChild($PartNumber);
		$DescriptionOfGood = $doc->createElement("DescriptionOfGood");
		$DescriptionOfGood->appendTextNode("Electronic Part: " . $item[$i]);
		$Goods->appendChild($DescriptionOfGood);
		$TariffCode = $doc->createElement("Inv-NAFTA-TariffCode");
		$TariffCode->appendTextNode("854231");
		$Goods->appendChild($TariffCode);
		$Origin = $doc->createElement("Inv-NAFTA-CO-CountryTerritoryOfOrigin");
		$Origin->appendTextNode("US");
		$Goods->appendChild($Origin);
		$InvoiceUnits = $doc->createElement("InvoiceUnits");
		$InvoiceUnits->appendTextNode($qty[$i]);
		$Goods->appendChild($InvoiceUnits);
		$InvoiceUnitOfMeasure = $doc->createElement("InvoiceUnitOfMeasure");
		$InvoiceUnitOfMeasure->appendTextNode("EA");
		$Goods->appendChild($InvoiceUnitOfMeasure);
		$UnitPrice = $doc->createElement("Invoice-SED-UnitPrice");
		$UnitPrice->appendTextNode(sprintf("%.2f", $price[$i]));
		$Goods->appendChild($UnitPrice);
		$InvoiceCurrencyCode = $doc->createElement("InvoiceCurrencyCode");
		$InvoiceCurrencyCode->appendTextNode("US");
		$Goods->appendChild($InvoiceCurrencyCode);
	}
	$filename = $refnum;
 	if ($specialchars > 1) {
		$filename .= "_specialchars"
	} elsif ($specialchars == 1) {
		$filename .= "_latinchars"
	}
 	if ($toolong) {
		$filename .= "_long"
	}
	$doc->toFile($filename . ".xml", 2);
	#print $doc->toString(2);
	#exit;
}

close $fh;
close $fref;
