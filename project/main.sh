#!/bin/bash
script="$0"
rootdir="$(dirname $script)"
echo "Located files in the following directory: $rootdir"

# Set working directory
cd $rootdir
#pwd

if [ "$1" = "scrape" ]
then

  # Save previous result
  mv data/scrapped_ted_talks.txt data/scrapped_ted_talks_old.txt
  touch data/scrapped_ted_talks.txt

  # Launch the TED Talk scrapper
  echo 'Launching scrapper:'
  python src/ted_scraper.py pwd

  # Organise the raw lines in a compact readable form
  echo 'Generating readable text data:'
  Rscript src/format_design.R pwd

elif [ "$1" = "analysis" ]
then
  
  # Text mining
  echo "Perform Text Analysis:"
  python src/text_analysis.py pwd

  # Answering the question
  echo 'Performing analytics on text mining results:'
  Rscript src/regressions.R pwd

else

  echo "Please specify 'scrape' or 'analysis' as  atrailing argument to use this script."

fi
# END
