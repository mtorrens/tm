#source('~/Desktop/tm_ted/src/format_design.R')
# Working directory
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  PATH <- '~/Desktop/tm_ted/'
} else {
  PATH <- paste(system(toString(args[1]), intern = TRUE), '/', sep = '')
}
setwd(PATH)

# Read the data and clean empty strings
file <- paste(PATH, 'data/scrapped_ted_talks.txt', sep = '')
ted <- readLines(file)
ted <- ted[nchar(ted) > 0]
cat('File read:', file, '\n')

# Identify strings that cut between talks
headers <- grep('^Title: ', ted)
cat('Number of talks identified:', length(headers), '\n')

# Create an empty data.frame to store all information
talks <- as.data.frame(matrix(nrow = length(headers), ncol = 10))
colnames(talks) <- c('title', 'speaker', 'date', 'tags', 'n_shares',
                     'topics', 'text', 'url', 'duration', 'filmed')

# Loop over talks
for (h in headers) {
  # Index all elements needed
  ctoken <- which(headers == h)
  if (ctoken != length(headers)) {
    ntoken <- headers[ctoken + 1]
  } else {
    ntoken <- length(ted) + 1
  }

  # Collect the metadata
  talks[ctoken, 1] <- gsub('Title: ', '', ted[h])
  talks[ctoken, 2] <- gsub('Speaker: ', '', ted[h + 1])
  talks[ctoken, 3] <- gsub('Date: ', '', ted[h + 2])
  talks[ctoken, 4] <- gsub('Tags: ', '', ted[h + 3])
  talks[ctoken, 5] <- as.numeric(gsub('Shares: ', '', ted[h + 4]))
  talks[ctoken, 6] <- gsub('Topics: ', '', ted[h + 5])
  talks[ctoken, 8] <- gsub('Original URL: ', '', ted[h + 8])
  talks[ctoken, 9] <- gsub('Time: ', '', ted[h + 6])
  talks[ctoken, 10] <- gsub('Filmed: ', '', ted[h + 7])

  # Concatenate the text in a readable form
  text <- ''
  for (j in (h + 9):(ntoken - 1)) {
    text <- paste(text, ted[j])
  }
  # suppress <- c('\\(Music\\)', '\\(Applause\\)')#, '\\(Laughter)\\)')
  # for (sup in suppress) {
  #   text <- gsub(sup, '', text)
  # }
  # #text <- iconv(text, from = 'utf-8', to = 'ASCII//TRANSLIT')
  talks[ctoken, 7] <- gdata::trim(gsub('\\s{2,}', ' ', text))
}

# Some talks are music / dance / others
talks <- talks[which(nchar(talks[, 'text']) > 0), ]
talks <- talks[which(talks[, 'n_shares'] > 0), ]
cat('Valid formatted talks:', nrow(talks), '\n')
#head(talks[order(nchar(talks[, 'text'])), ], 10)

# Save the data in various formats
save(talks, file = 'data/scrapped_ted_talks.RData')
write.csv(talks, file = 'data/scrapped_ted_talks.csv', row.names = FALSE)
cat('File saved: data/scrapped_ted_talks.RData\n')
cat('File written: data/scrapped_ted_talks.csv\n')

# JSON
cat('Generating JSON... ')
json.talks <- '{ '
for (i in 1:nrow(talks)) {
  json.talks <- paste(json.talks, rjson::toJSON(talks[1, ]), ', ', sep = '')
}
json.talks <- paste(json.talks, rjson::toJSON(talks[nrow(talks), ]), '}')
cat('Done!\n')
cat(json.talks, file = 'data/scrapped_ted_talks.json')
cat('File written: data/scrapped_ted_talks.json\n')

# List of words that appear only once in the corpus
words <- tolower(unlist(strsplit(gsub('\\W+', ' ', talks[, 'text']), ' ')))
tt <- sort(table(words))
alone <- names(tt[tt == 1])
cat(alone[1], '\n', file = 'input/lonely_words.txt')
aux <- sapply(alone[2:length(alone)], function(x) {
  cat(x, '\n', file = 'input/lonely_words.txt', append = TRUE)
})
# END OF SCRIPT
