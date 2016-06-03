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

def remove_rare(tokens):
  global urare
  filtered = []
  for token in tokens:
    if token not in urare:
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

def savetxt_compact(fname, x, fmt = "%.6g", delimiter = ','):
  with open(fname, 'w') as fh:
    for row in x:
      line = delimiter.join('0' if value == 0 else fmt % value for value in row)
      fh.write(line + '\n')

def load_sent_dict(path):
  d = {}
  with open(path, 'rb') as csv_file:
    csv_reader = csv.reader(csv_file, delimiter='\t')
    for row in csv_reader:
      d[row[0]] = int(row[1])        

  return(d)

################################################################################
