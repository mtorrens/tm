################################################################################
# Analysis functions
def corpus_tokens(corpus):
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
  aux = list(token_set)
  vector = [0] * len(token_set)
  words = list(set(document))
  counter = Counter(document)
  for i in range(len(words)):
    vector[aux.index(words[i])] = counter[words[i]]
  return vector

def dict_rank(dictionary, use_tf_idf, ntop):
  global token_set, stemmed_list
  if (use_tf_idf):
    global tfidf_matrix
    mat = tfidf_matrix
  else:
    global res
    mat = res
  
  # Get rid of words in the document term matrix not in the dictionary
  dict_tokset = set(item for item in dictionary)
  intersec = dict_tokset & token_set
  vec_pos = [int(token in intersec) for token in token_set] 
  
  # Get the score of each document
  sums = np.zeros(len(mat))
  for j in range(len(mat)):
    sums[j] = sum([a * b for a, b in zip(mat[j], vec_pos)])
  
  # Order them and return the n top documents
  order = sorted(range(len(sums)), key = lambda k: sums[k], reverse = True)
  # ordered_docs = [None] * len(dtm)
  # ordered_sums = np.zeros(len(dtm))
  
  # counter = 0
  # for num in order:
  #     ordered_docs[counter] = stemmed_list[num]
  #     ordered_sums[counter] = sums[num]
  #     counter += 1
  
  # return zip(ordered_docs[0:ntop], ordered_sums[0:ntop])
  return zip(order[0:ntop], sums[0:ntop])

def calc_sentiment_words(sentiment_dict, words):
  rec_wcount = 0
  sentiment = 0

  # For all words in the word list, look up the sentiment in the sentiment
  # dictionary, and if and only if it is found, increment a cumulative
  # sentiment score and a count of words recognized by the sentiment
  # dictionary.
  for word in words:
    if sentiment_dict.has_key(word):
      sentiment += sentiment_dict[word]
      rec_wcount += 1

  # Return a 2-tuple containing the average sentiment and the total
  # cumulated sentiment.
  try:
    cum_sent = float(sentiment) / float(rec_wcount)
  except:
    cum_sent = 0

  return cum_sent, sentiment

################################################################################
