#!/usr/bin/python
# -*- coding: utf-8 -*-
################################################################################
# Dependencies
import sys, os, re, csv, lda
import pandas as pd
import nltk as nl
import codecs as co
import numpy as np
from collections import Counter
from math import log
################################################################################

################################################################################
# Working directory
print 'Script: LDA Analysis\nOrientative execution time: ~1H'
try:
  root = re.sub('\n', '', os.popen(sys.argv[1]).read())
except:
  root = '/Users/miquel/Desktop/tm_ted'
os.chdir(root)
print 'Detected project path to: ' + root

# Load functions
print 'Loaded functions: src/functions_cleaning.py'
execfile('src/functions_cleaning.py')
print 'Loaded functions: src/functions_analysis.py'
execfile('src/functions_analysis.py')

# Parameters
compute_dtm = True
################################################################################

################################################################################
# Stopwords
print 'Stopwords used: input/stopwords.txt'
with co.open('input/stopwords.txt', 'r', 'utf-8') as obj: 
  stopwords = set(obj.read().splitlines())

# Rare words
print 'Rare word list used: input/lonely_words.txt'
with co.open('input/lonely_words.txt', 'r', 'utf-8') as obj: 
  rarewords = obj.read().splitlines()
  rarewords = [i.strip() for i in rarewords]
#urare = set(stem_tokens(rarewords))
urare = set(rarewords)

# Harvard IV set
print 'Dictionary used: input/inquirerbasic2.csv'
dictionary = np.loadtxt(open('input/inquirerbasic2.csv', 'rb'),
                        dtype = 'str', delimiter = ';', skiprows = 1,
                        comments = None)
our_dict = sorted(set(i[0].rstrip('#01234256789').lower() for i in dictionary))

# Load the sentiment dictionary
print 'Sentiment dictionary used: input/AFINN-111.txt'
sent_dict = load_sent_dict('input/AFINN-111.txt')
################################################################################

################################################################################
# Loading, cleaning and counting the data
print 'Read scrapped talks file: data/scrapped_ted_talks.csv'
talks = pd.read_csv('data/scrapped_ted_talks.csv')
nptalks = np.array(talks)
text = talks.text

# Convert it into a list of strings in lower case without numbers
print 'Tokenizing...'
text_list = []
for i in range(len(text)):
  new_text = re.sub(r'\W+', ' ', text[i])
  text_list.append(new_text.lower())

# Break the text into words
word_list = [text_list[i].split() for i in range(len(text_list))]

# Suppress strings we don't like
print 'Cleaning wordlist...'
clean_list = [clean_wordlist(word_list[i]) for i in range(len(word_list))]

# Supress rare words
print 'Supressing rare words...'
freq_list = [remove_rare(clean_list[i]) for i in range(len(clean_list))]

# Supress stopwords
print 'Removing stopwords...'
rel_list = [remove_stopwords(freq_list[i]) for i in range(len(freq_list))]

# Stem words and suppress possible remaining stopwords
print 'Stemming...'
stem_list = [stem_tokens(rel_list[i]) for i in range(len(rel_list))]
stem_list = [remove_stopwords(stem_list[i]) for i in range(len(stem_list))]

# Set of tokens
token_set = corpus_tokens(stem_list)

# Compute the document term matrix
print 'Creating document term matrix (this may take a while)...'
if compute_dtm:
  res = doc_term_matrix(stem_list)
  dtm = np.array(res)
  print 'Done.\nDTM: {} docs and {} words'.format(dtm.shape[0], dtm.shape[1])
  # Save the document term matrix
  #savetxt_compact('data/dtm.csv', dtm, delimiter = ',')
  print 'Writing DTM file... data/dtm.csv'
  with open('data/dtm.csv', 'wb') as obj:
    writer = csv.writer(obj)
    writer.writerow(list(token_set))
    writer.writerows(dtm)
else:
  res = []
  with open('data/dtm.csv', 'rb') as obj:
    content = csv.reader(obj)
    for row in content:
      res.append(row)
      #dtm.join(row)
  #dtm = np.array(res[1:len(res)], dtype = 'i')
  dtm = np.array(res[1:len(res)], dtype = 'f')
  print 'DTM: {} docs and {} words'.format(dtm.shape[0], dtm.shape[1])
  res = res[1:len(res)]
  fres = []
  for elem in res:
    felem = []
    for item in elem:
      felem.append(float(item))
    fres.append(felem)
  res = fres

# Set unique tags
unique_tags = []
tags = list(talks.tags)
for i in range(len(tags)):
  tags[i] = tags[i].lower()
  tags[i] = re.sub(r',', '', tags[i])
  tags[i] = tags[i].split()
  for j in range(len(tags[i])):
    unique_tags.append(tags[i][j])

unique_tags = set(unique_tags)
print 'Written unique tags: data/list_tags.csv'
with open('data/list_tags.csv', 'wb') as obj:
  writer = csv.writer(obj)
  writer.writerow(list(unique_tags))

# Set unique topics
unique_topics = []
topics = list(talks.topics)
for i in range(len(topics)):
  if not isinstance(topics[i], float):
    topics[i] = re.sub(r'nan', 'nans', topics[i])
    topics[i] = topics[i].lower()
    topics[i] = re.sub(r',', '', topics[i])
    topics[i] = topics[i].split()
    for j in range(len(topics[i])):
      unique_topics.append(topics[i][j])

unique_topics = set(unique_topics)
print 'Written unique topics: data/list_topics.csv'
with open('data/list_topics.csv', 'wb') as obj:
  writer = csv.writer(obj)
  writer.writerow(list(unique_topics))

################################################################################
# Dictionary methods
# Build a term frequency matrix from the document term matrix.
tf_matrix = []
for i in res:
  new_vector = [(0 if x == 0 else 1 + log(x)) for x in i]
  tf_matrix.append(new_vector)

tfm = np.array(tf_matrix)

# Build a document frequency matrix for each term.
df_vec = np.zeros(len(token_set))
for i in res:
  df_vec = np.add(df_vec, [int(x > 0) for x in i])

# Build an inverse document frequency vector
idf_vec = [log(len(stem_list) / x) for x in df_vec]

# Build the TF-IDF weighting matrix.
tfidf_matrix = []
for i in tf_matrix:
  tfidf_vec = np.multiply(i, idf_vec)
  tfidf_matrix.append(tfidf_vec)

#tfidfm = np.array(tfidf_matrix)
tfidfm = tfidf_matrix
################################################################################

################################################################################
# Score the documents
print 'Scoring documents and evaluating sentiment...'
dtm_rank = dict_rank(our_dict, False, ntop = len(stem_list))
tfidf_rank = dict_rank(our_dict, True, ntop = len(stem_list))
#aux = [dtm_rank[i][0] == 0 for i in range(len(dtm_rank))]
#np.where(np.array(aux) == True)

# Sentiment
sentiment = []
for i in range(len(stem_list)):
  sent, cum_sent = calc_sentiment_words(sent_dict, stem_list[i])
  sentiment.append([i, sent, cum_sent])
sentiment = np.array(sentiment)
print 'Done.'

# Save stuff
print 'Writing file... data/dtm_score.csv'
with open('data/dtm_score.csv', 'wb') as obj:
  writer = csv.writer(obj)
  writer.writerow(['index', 'dtm_score'])
  writer.writerows(np.array(dtm_rank))

print 'Writing file... data/tfidf_score.csv'
with open('data/tfidf_score.csv', 'wb') as obj:
  writer = csv.writer(obj)
  writer.writerow(['index', 'tfidf_score'])
  writer.writerows(np.array(tfidf_rank))

print 'Writing file... data/sentiment.csv'
with open('data/sentiment.csv', 'wb') as obj:
  writer = csv.writer(obj)
  writer.writerow(['index', 'sentiment', 'cum_sentiment'])
  writer.writerows(np.array(sentiment))

################################################################################

################################################################################
# Latent Dirichlet Allocation
# Compute parameters
print 'Performing LDA:'
n_topics = 12
model = lda.LDA(n_topics = n_topics, n_iter = 3000, random_state = 1)

# Small tweak
if not compute_dtm:
  dtm = np.array(dtm, dtype = np.int64)

# Fit the model
model.fit(dtm)

# Compute top words and topic probability for each document
topic_word = model.topic_word_
topic_probs = model.doc_topic_

n_twords = 10
vocab = tuple(token_set)
for i, tdist in enumerate(topic_word):
  twords = np.array(vocab)[np.argsort(tdist)][:-(n_twords + 1):-1]
  print('Topic {}: {}'.format(i, ' '.join(twords)))

for i in range(10):
  print("{} (top topic: {})".format(talks.title[i], topic_probs[i].argmax()))

# Save results
colnames = []
for i in range(n_topics):
  colnames.append('prob_topic_{}'.format(str(i).zfill(2)))

print 'Saved file: data/lda_probs.csv'
with open('data/lda_probs.csv', 'wb') as obj:
  writer = csv.writer(obj)
  writer.writerow(colnames)
  writer.writerows(topic_probs)

print 'END OF SCRIPT\n'
################################################################################
# END OF SCRIPT
