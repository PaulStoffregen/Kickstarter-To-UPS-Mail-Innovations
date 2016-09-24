rm -f *.xml
./kickstarter2mailinnovations.pl  23.00*.csv a.txt
./kickstarter2mailinnovations.pl  28.00*.csv b.txt
./kickstarter2mailinnovations.pl  45.00*.csv c.txt
./kickstarter2mailinnovations.pl  50.00*.csv d.txt
./kickstarter2mailinnovations.pl  55.00*.csv e.txt
./kickstarter2mailinnovations.pl  72.00*.csv f.txt
./kickstarter2mailinnovations.pl  77.00*.csv g.txt
./kickstarter2mailinnovations.pl  82.00*.csv h.txt
./kickstarter2mailinnovations.pl 100.00*.csv j.txt
./kickstarter2mailinnovations.pl 129.00*.csv k.txt
./kickstarter2mailinnovations.pl 160.00*.csv m.txt
./kickstarter2mailinnovations.pl 216.00*.csv n.txt
./kickstarter2mailinnovations.pl 295.00*.csv p.txt
./kickstarter2mailinnovations.pl 300.00*.csv r.txt
rm -f Kickstarter_XML.zip
zip -9 Kickstarter_XML.zip *.xml
