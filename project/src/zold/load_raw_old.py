
################################################################################
# Dependencies
import os, re
import pandas as pd
import nltk as nl
import codecs
from collections import Counter
#import numpy as np
#from nltk.tokenize import wordpunct_tokenize
#from nltk import PorterStemmer
################################################################################

################################################################################
# Working directory
root = '/Users/miquel/Desktop/tm_ted'
#os.getcwd()
os.chdir(root)
################################################################################

################################################################################
# Stopwords
with codecs.open('input/stopwords.txt', 'r', 'utf-8') as obj: 
  stopwords = set(obj.read().splitlines())

# # Standard list of contractions
# contractions = {
#   u"ain't" : u"is not",
#   u"aren't" : u"are not",
#   u"can't" : u"cannot",
#   u"could've" : u"could have",
#   u"couldn't" : u"could not",
#   u"didn't" : u"did not",
#   u"doesn't" : u"does not",
#   u"don't" : u"do not",
#   u"hadn't" : u"had not",
#   u"hasn't" : u"has not",
#   u"haven't" : u"have not",
#   u"he'd" : u"he would",
#   u"he'll" : u"he will",
#   u"he's" : u"he is",
#   u"how'd" : u"how did",
#   u"how'll" : u"how will",
#   u"how's" : u"how is",
#   u"i'd" : u"i would",
#   u"i'll" : u"i will",
#   u"i'm" : u"i am",
#   u"i've" : u"i have",
#   u"isn't" : u"is not",
#   u"it'd" : u"it would",
#   u"it'll" : u"it will",
#   u"it's" : u"it is",
#   u"let's" : u"let us",
#   u"ma'am" : u"madam",
#   u"might've" : u"might have",
#   u"must've" : u"must have",
#   u"needn't" : u"need not",
#   u"o'clock" : u"of the clock",
#   u"shan't" : u"shall not",
#   u"she'd" : u"she would",
#   u"she'll" : u"she will",
#   u"she's" : u"she is",
#   u"should've" : u"should have",
#   u"shouldn't" : u"should not",
#   u"that'd" : u"that would",
#   u"that'll" : u"that will",
#   u"that's" : u"that is",
#   u"there'd" : u"there would",
#   u"there'll" : u"there will",
#   u"there's" : u"there is",
#   u"they'd" : u"they would",
#   u"they'll" : u"they will",
#   u"they're" : u"they are",
#   u"they've" : u"they have",
#   u"wasn't" : u"was not",
#   u"we'd" : u"we would",
#   u"we'll" : u"we will",
#   u"we're" : u"we are",
#   u"we've" : u"we have",
#   u"weren't" : u"were not",
#   u"what'll" : u"what will",
#   u"what're" : u"what are",
#   u"what's" : u"what is",
#   u"when's" : u"when is",
#   u"where'd" : u"where did",
#   u"where's" : u"where is",
#   u"where've" : u"where have",
#   u"who'll" : u"who will",
#   u"who's" : u"who is",
#   u"who've" : u"who have",
#   u"why's" : u"why is",
#   u"won't" : u"will not",
#   u"would've" : u"would have",
#   u"wouldn't" : u"would not",
#   u"y'all" : u"you all",
#   u"you'd" : u"you would",
#   u"you'll" : u"you will",
#   u"you're" : u"you are",
#   u"you've" : u"you have"
# }
################################################################################

################################################################################
# Load the data
talks = pd.read_csv('data/scrapped_ted_talks.csv')
text = talks.text

# Convert it into a list of strings in lower case without numbers
text_list = []
for i in range(len(text)):
  new_text = re.sub(r'\W+', ' ', text[i])
  # for key in contractions.keys():
  #   new_text = re.sub(key, contractions[key], text[i])
  text_list.append(new_text.lower())

# Break the text into words
word_list = [text_list[i].split() for i in range(len(text_list))]

# Suppress strings we don't like
clean_list = [clean_wordlist(word_list[i]) for i in range(len(word_list))]

# Supress stopwords
rel_list = [remove_stopwords(clean_list[i]) for i in range(len(clean_list))]

# Stem the crap out of the text
stemmed_list = [stem_tokens(rel_list[i]) for i in range(len(rel_list))]

# Set of tokens
token_set = corpus_tokens(stemmed_list)

# Compute the document term matrix
res = doc_term_matrix(stemmed_list)
# import textmining as tm
# tdm = tm.TermDocumentMatrix()
# for i in range(len(text_list)):
#   tdm.add_doc(text_list[i])
# tdm.write_csv('matrix.csv', cutoff=1)

################################################################################


################################################################################
# Cleaning functions
def clean_wordlist(words):
  chosen = []
  for w in words:
    if w.isalpha() == 1 and len(w) > 1:
    #if w.isalnum() == 1 and len(w) > 1:
      chosen.append(w)
  return chosen

def remove_stopwords(tokens):
  global stopwords
  filtered = []
  for token in tokens:
    if token not in stopwords:
      filtered.append(token)
  return filtered

def unite_bigrams(tokens):
  bigs = nl.bigrams(tokens)
  result = map(lambda x: x[0] + '.' + x[1], bigs)
  return result

def stem_tokens(tokens):
  stemmed_tokens = []
  for token in tokens:
    stemmed_tokens.append(nl.PorterStemmer().stem(token))
  return stemmed_tokens


################################################################################
# Analysis functions
def corpus_tokens(corpus):
  # Initialise an empty set
  token_set = set()
  for i in range(len(corpus)):
    token_set = token_set.union(corpus[i]) 
  return token_set

def doc_term_matrix(corpus):
  result = []
  for i in range(len(corpus)):
    vector = term_vector(corpus[i])
    result.append(vector)        
  return result

def term_vector(document):
  global token_set
  vector = [0] * len(token_set)
  words = list(set(document))
  counter = Counter(document)
  for i in range(len(words)):
    vector[list(token_set).index(words[i])] = counter[words[i]]
  return vector





