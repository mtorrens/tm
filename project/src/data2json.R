#source('~/Desktop/tm_ted/src/data2json.R')
# Working directory
PATH <- '~/Desktop/tm_ted/'
setwd(PATH)

# Read the data and clean empty strings
file <- paste(PATH, 'data/scrapped_ted_talks.txt', sep = '')
ted <- readLines(file)
ted <- ted[nchar(ted) > 0]
cat('File read:', file, '\n')

# Identify strings that cut between talks
headers <- grep('^Title: ', ted)

# Create an empty data.frame to store all information
cols <- c('title', 'speaker', 'date', 'tags', 'n_shares', 'topics', 'text')
talks <- as.data.frame(matrix(nrow = length(headers), ncol = 7))
colnames(talks) <- cols

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

  # Concatenate the text in a readable form
  text <- ''
  for (j in (h + 6):(ntoken - 1)) {
    text <- paste(text, ted[j])
  }
  talks[ctoken, 7] <- gdata::trim(text)
}

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
# END OF SCRIPT
