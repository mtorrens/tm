
## Text Mining Project: Analysing the effect of content of speech on viewership results

Author: Miquel Torrens (c) 2016

### How to run the code

To run the code of this project in your local machine, you will need to clone the repository and execute the shell script ``main.sh``. It is a simple script which can be inspected prior to execution to make sure it is compatible with your machine. If any command therein is not installed or the path is not correctly referenced in your local machine, please feel free to adapt it for your case, or simply perform manually the commands of the script (self-explanatory). This step is necessary for any Windows user.

### Software requirements

The project was developed under a Unix environment and is not designed to run on Windows (not supported). The code runs partly in Python and partly R, and it was developed under ``python 2.7.10`` and ``R 3.2.2`. Compatibility with any other version **is not guaranteed** for either of them.

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

R package dependencies (only necessary for plots and tables):

 * `stargazer`
 * `tikzDevice`
 * `corrplot`

Be aware that the code **will not force the installation** of any dependency or any software piece whatsoever. They need to be installed manually for security reasons.
