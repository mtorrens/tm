#!/bin/bash
script="$0"
rootdir="$(dirname $script)"
echo "Located files in the following directory: $rootdir"

# Set working directory
cd $rootdir
pwd

if [ "$1" = "scrape" ]
then

  # Save previous result
  mv data/scrapped_ted_talks.txt data/scrapped_ted_talks_old.txt

  # Launch the TED Talk scrapper
  echo 'Launching scrapper:'
  python src/ted_scraper.py

  # Organise the raw lines in a compact readable form
  echo 'Generating readable text data:'
  Rscript src/data2json.R

elif [ "$1" = "execute" ]
then

  echo "Execute the project."

else

  echo "Please specify 'scrape' or 'execute' to use this script."

fi
# END
