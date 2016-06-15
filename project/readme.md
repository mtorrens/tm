## [Text Mining Project] Analysing the effect of content of speech on viewership results

*Author*: Miquel Torrens (c) 2016

### How to run the code

To run the code of this project in your local machine, you will need to clone the repository and execute the shell script ``main.sh``. It is a simple script which can be inspected prior to execution to make sure it is compatible with your machine. If any command therein is not installed or the path is not correctly referenced in your local machine, please feel free to adapt it for your case, or simply perform manually the commands of the script (self-explanatory). This step is necessary for any Windows user.

This script can be run in two modes:

 1. **Scrapper mode**: to run the scrapper on the TED website. Execute from terminal:
 
 `bash <path/to/script>/main.sh scrape`
 
 2. **Analysis mode**: to perform all the analysis, charts and tables of the project. **This is the only command to execute if we want to replicate the exact results from the report**. Execute from terminal:
 
 `bash <path/to/script>/main.sh analysis`

Please provide attention to the messages that appear on the screen throughout the execution, as they may have relevant information.

### Software requirements

The project was developed under a Unix environment and is not designed to run on Windows (not supported). The code runs partly in Python and partly R, and it was developed under `python 2.7.10` and `R 3.2.2`. Compatibility with any other version **is not guaranteed** for either of them.

Python library dependencies:

 * `sys`
 * `os`
 * `re`
 * `csv`
 * `lda`
 * `pandas`
 * `nltk`
 * `codecs`
 * `numpy`
 * `collections`
 * `math`
 * `urllib2`
 * `urllib`
 * `urlparse`
 * `html`
 * `time`
 * `random`

R package dependencies:

 * `gdata`
 * `rjson`
 * `stargazer`
 * `tikzDevice`
 * `corrplot`

Be aware that the code **will not force the installation** of any dependency or any software piece whatsoever. They need to be installed manually for security reasons.
