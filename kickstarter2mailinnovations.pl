#!/usr/bin/env perl

# convert a Kickstarter CSV file to many UPS Worldship XML files
# for use with the "XML Auto Import" feature.

use warnings;
use strict;
use Encode;
use Data::Dumper;

use Text::CSV; # sudo apt-get install libtext-csv-perl
use XML::LibXML; # sudo apt-get install libxml-libxml-perl

my $csv = Text::CSV->new({ binary => 1 });

(exists $ARGV[0] && $ARGV[0] =~ /\.csv$/ && exists $ARGV[1] && $ARGV[1] =~ /^([a-zA-Z])\.txt$/)
    or die "usage: kickstarter2mailinnovations.pl file.csv N.txt\n";
my $reward = uc($1);
-r $ARGV[0] or die "Unable to read \"$ARGV[0]\"\n";
-r $ARGV[1] or die "Unable to read \"$ARGV[1]\"\n";

my @items;

open(my $txtfh, "<", $ARGV[1]) or die "$!";
my $numitems = 0;
my $total    = 0;
while (my $line = <$txtfh>) {
    #print "Item: $_\n";

    my ($qty, $name, $price) = split(' ', $line);
    push @items, { qty => $qty, name => $name, price => $price };
    $total += $price * $qty;
    $numitems++;
    #@list = split;
    #print "Item: $list[0] ", join(", ", @list), "\n";
}
close($txtfh);

print "total:  $total\n";
print "Reward: $reward\n";
print "File: $ARGV[0]\n";

open(my $csvfh, "<", $ARGV[0]) or die "$!";
#open $fh, "<:encoding(utf8)", $ARGV[0] or die "$!";
open(my $fref, ">>", "allrefnums.txt") or die "$!";

my $header = $csv->getline($csvfh);

while (my $row = $csv->getline($csvfh)) {
    my $specialchars = 0;
    my $toolong      = 0;
    my $name         = $row->[15];
    my $addr1        = $row->[16];
    my $addr2        = $row->[17];
    my $city         = $row->[18];
    my $state        = $row->[19];
    my $postalcode   = $row->[20];
    my $country      = $row->[21];
    my $phone        = $row->[23];
#  print Dumper({name => $name, addr1 => $addr1, addr2 => $addr2, city => $city, state => $state, postalcode => $postalcode, country =>$country, phone => $phone});
    next unless $country;

    my $refnum = $reward . sprintf("%04d", $row->[0]);
    print $fref "$refnum\n";

    next if $country eq "United States";
    if ($country eq "Brunei Darussalam") {
        $country = "Brunei";
    }
    elsif ($country eq "China") {
        $country = "China, People's Republic of";
    }
    elsif ($country eq "Korea, Republic of") {
        $country = "Korea, South";
    }
    elsif ($country eq "Russian Federation") {
        $country = "Russia";
    }

    if (   length($name) > 35
        || length($addr1) > 35
        || length($addr2) > 35
        || length($city) > 30
        || length($postalcode) > 35
        || length($phone) > 15)
    {
        $toolong = 1;
    }

    my $all = $name . $addr1 . $addr2 . $city . $state . $postalcode . $country . $phone;
    if ($all =~ /[\x{100}-\x{FFFF}]/) {
        $specialchars = 2;
    }
    elsif ($all =~ /[\x{80}-\x{FF}]/) {
        $specialchars = 1;
    }

    print "Ref #:   ", $refnum, ",  ";
    print "Backer:  ", $row->[2], "\n";

    my $doc = XML::LibXML::Document->new("1.0", "UTF-8");

    # TODO I'm fairly certain this XML generation code could be cleaned up further
    # with some gratuitous use of method chaining and fewer variables but I'm not going
    # to even attempt it since I don't have a way to test the output properly. --rvoots

    my $OpenShipments = $doc->createElement("OpenShipments");
    $doc->setDocumentElement($OpenShipments);
    $OpenShipments->setAttribute("xmlns" => "x-schema:OpenShipments.xdr");

    my $OpenShipment = $doc->createElement("OpenShipment");
    $OpenShipments->appendChild($OpenShipment);
    $OpenShipment->setAttribute("ShipmentOption" => "SP");
    $OpenShipment->setAttribute("ProcessStatus"  => "");

    my $ShipTo = $doc->createElement("ShipTo");
    $OpenShipment->appendChild($ShipTo);

    my $CompanyOrName = $doc->createElement("CompanyOrName");
    $CompanyOrName->appendTextNode($name);
    $ShipTo->appendChild($CompanyOrName);
    my $Attention = $doc->createElement("Attention");
    $Attention->appendTextNode($name);
    $ShipTo->appendChild($Attention);
    my $Address1 = $doc->createElement("Address1");
    $Address1->appendTextNode($addr1);
    $ShipTo->appendChild($Address1);

    if ($addr2) {
        my $Address2 = $doc->createElement("Address2");
        $Address2->appendTextNode($addr2);
        $ShipTo->appendChild($Address2);
    }
    my $CountryTerritory = $doc->createElement("CountryTerritory");
    $CountryTerritory->appendTextNode($country);
    $ShipTo->appendChild($CountryTerritory);
    my $PostalCode = $doc->createElement("PostalCode");
    $PostalCode->appendTextNode($postalcode);
    $ShipTo->appendChild($PostalCode);
    my $CityOrTown = $doc->createElement("CityOrTown");
    $CityOrTown->appendTextNode($city);
    $ShipTo->appendChild($CityOrTown);
    my $StateProvinceCounty = $doc->createElement("StateProvinceCounty");
    $StateProvinceCounty->appendTextNode($state);
    $ShipTo->appendChild($StateProvinceCounty);
    my $Telephone = $doc->createElement("Telephone");
    $Telephone->appendTextNode($phone);
    $ShipTo->appendChild($Telephone);

    my $ShipmentInformation = $doc->createElement("ShipmentInformation");
    $OpenShipment->appendChild($ShipmentInformation);
    my $ServiceType = $doc->createElement("ServiceType");
    $ServiceType->appendTextNode("MIP");
    $ShipmentInformation->appendChild($ServiceType);
    my $PackageType = $doc->createElement("PackageType");
    $PackageType->appendTextNode("Parcels");
    $ShipmentInformation->appendChild($PackageType);
    my $NumberOfPackages = $doc->createElement("NumberOfPackages");
    $NumberOfPackages->appendTextNode("1");
    $ShipmentInformation->appendChild($NumberOfPackages);
    my $ShipmentActualWeight = $doc->createElement("ShipmentActualWeight");
    $ShipmentActualWeight->appendTextNode("0.1");
    $ShipmentInformation->appendChild($ShipmentActualWeight);
    my $DescriptionOfGoods = $doc->createElement("DescriptionOfGoods");
    $DescriptionOfGoods->appendTextNode("Electronic Parts");
    $ShipmentInformation->appendChild($DescriptionOfGoods);
    my $Reference1 = $doc->createElement("Reference1");
    $Reference1->appendTextNode($refnum);
    $ShipmentInformation->appendChild($Reference1);
    my $Reference2 = $doc->createElement("Reference2");
    $Reference2->appendTextNode("KS");
    $ShipmentInformation->appendChild($Reference2);
    my $BillTransportationTo = $doc->createElement("BillTransportationTo");
    $BillTransportationTo->appendTextNode("Shipper");
    $ShipmentInformation->appendChild($BillTransportationTo);
    my $BillDutyTaxTo = $doc->createElement("BillDutyTaxTo");
    $BillDutyTaxTo->appendTextNode("Receiver");
    $ShipmentInformation->appendChild($BillDutyTaxTo);

    my $InternationalDocumentation = $doc->createElement("InternationalDocumentation");
    $OpenShipment->appendChild($InternationalDocumentation);
    my $CustomsValueTotal = $doc->createElement("CustomsValueTotal");
    $CustomsValueTotal->appendTextNode(sprintf("%.2f", $total));
    $InternationalDocumentation->appendChild($CustomsValueTotal);
    my $CustomsValueCurrencyCode = $doc->createElement("CustomsValueCurrencyCode");
    $CustomsValueCurrencyCode->appendTextNode("USD");
    $InternationalDocumentation->appendChild($CustomsValueCurrencyCode);
    my $InvoiceCurrencyCode = $doc->createElement("InvoiceCurrencyCode");
    $InvoiceCurrencyCode->appendTextNode("US");
    $InternationalDocumentation->appendChild($InvoiceCurrencyCode);
    my $CN22GoodsType = $doc->createElement("CN22GoodsType");
    $CN22GoodsType->appendTextNode("4");
    $InternationalDocumentation->appendChild($CN22GoodsType);
    my $CN22GoodsTypeOtherDescription = $doc->createElement("CN22GoodsTypeOtherDescription");
    $CN22GoodsTypeOtherDescription->appendTextNode("Electronic Parts");
    $InternationalDocumentation->appendChild($CN22GoodsTypeOtherDescription);

    for my $item (@items) {
        my $Goods = $doc->createElement("Goods");
        $OpenShipment->appendChild($Goods);
        my $PartNumber = $doc->createElement("PartNumber");
        $PartNumber->appendTextNode($item->{name});
        $Goods->appendChild($PartNumber);
        my $DescriptionOfGood = $doc->createElement("DescriptionOfGood");
        $DescriptionOfGood->appendTextNode("Electronic Part: " . $item->{name});
        $Goods->appendChild($DescriptionOfGood);
        my $TariffCode = $doc->createElement("Inv-NAFTA-TariffCode");
        $TariffCode->appendTextNode("854231");
        $Goods->appendChild($TariffCode);
        my $Origin = $doc->createElement("Inv-NAFTA-CO-CountryTerritoryOfOrigin");
        $Origin->appendTextNode("US");
        $Goods->appendChild($Origin);
        my $InvoiceUnits = $doc->createElement("InvoiceUnits");
        $InvoiceUnits->appendTextNode($item->{qty});
        $Goods->appendChild($InvoiceUnits);
        my $InvoiceUnitOfMeasure = $doc->createElement("InvoiceUnitOfMeasure");
        $InvoiceUnitOfMeasure->appendTextNode("EA");
        $Goods->appendChild($InvoiceUnitOfMeasure);
        my $UnitPrice = $doc->createElement("Invoice-SED-UnitPrice");
        $UnitPrice->appendTextNode(sprintf("%.2f", $item->{price}));
        $Goods->appendChild($UnitPrice);
        my $InvoiceCurrencyCode = $doc->createElement("InvoiceCurrencyCode");
        $InvoiceCurrencyCode->appendTextNode("US");
        $Goods->appendChild($InvoiceCurrencyCode);
    }
    my $filename = $refnum;
    if ($specialchars > 1) {
        $filename .= "_specialchars";
    }
    elsif ($specialchars == 1) {
        $filename .= "_latinchars";
    }
    if ($toolong) {
        $filename .= "_long";
    }
    $doc->toFile($filename . ".xml", 2);
}
