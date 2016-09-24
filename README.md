Originally created by Paul St...ington for the Teensy 3.5/3.6 kickstarter
Updated to handle unicode slightly better by Ryan Voots

To install the needed perl libraries use the (cpanminus)[https://github.com/miyagawa/cpanminus] client

	cpanm --installdeps .

To run the program you'll need the CSV files from kickstarter broken out by reward levels.  
Each .txt file contains a list of the products for each level and is used for generating the invoice/reference numbers.

	./kickstarter2mailinnovations.pl test.csv a.txt

See run.sh for a little more information about automating this process.
	
