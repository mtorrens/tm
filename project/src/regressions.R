################################################################################
# Working directory
PATH <- '~/Desktop/tm_ted/'
setwd(PATH)
################################################################################

################################################################################
# Load different results from Python
file1 <- paste(PATH, 'data/dtm_score.csv', sep = '')
file2 <- paste(PATH, 'data/lda_probs.csv', sep = '')
file3 <- paste(PATH, 'data/list_tags.csv', sep = '')
file4 <- paste(PATH, 'data/sentiment.csv', sep = '')
file5 <- paste(PATH, 'data/list_topics.csv', sep = '')
file6 <- paste(PATH, 'data/tfidf_score.csv', sep = '')
file7 <- paste(PATH, 'data/scrapped_ted_talks.RData', sep = '')

# TED Talks
talks <- get(load(file = file7)); cat('Loaded file:', file7, '\n')

# Tags
tags <- readLines(file3); cat('Read file:', file3, '\n')
tags <- sort(unlist(strsplit(tags, ',')))

# Topics
topics <- readLines(file5); cat('Read file:', file5, '\n')
topics <- sort(unlist(strsplit(topics, ',')))

# Document Term Matrix score
dtms <- read.csv(file = file1); cat('Read file:', file1, '\n')
dtms <- dtms[order(dtms[, 1], decreasing = FALSE), ]
dtms[, 1] <- dtms[, 1] + 1
rownames(dtms) <- NULL

# TF-IDF score
tfidfs <- read.csv(file = file6); cat('Read file:', file6, '\n')
tfidfs <- tfidfs[order(tfidfs[, 1], decreasing = FALSE), ]
tfidfs[, 1] <- tfidfs[, 1] + 1
rownames(tfidfs) <- NULL

# Sentiment
sentiment <- read.csv(file = file4); cat('Read file:', file4, '\n')
sentiment[, 1] <- sentiment[, 1] + 1

# LDA Results
lda.res <- read.csv(file = file2); cat('Read file:', file2, '\n')
#corrplot::corrplot(cor(lda.res))
################################################################################

################################################################################
# Build the design matrix
#Sys.setlocale('LC_CTYPE', 'C')
Sys.setlocale('LC_TIME', 'C')
input <- as.data.frame(matrix(nrow = nrow(talks), ncol = 0))
input[, 1] <- 1:nrow(input)
input[, 2] <- talks[, 'n_shares']
input[, 3] <- nchar(talks[, 'text'])
input[, 4] <- as.Date(paste('1', tolower(talks[, 'date'])), '%d %b %Y')
input[, 5] <- tolower(talks[, 'tags'])
input[, 6] <- tolower(talks[, 'topics'])
input[, 7] <- dtms[match(input[, 1], dtms[, 'index']), 'dtm_score']
input[, 8] <- tfidfs[match(input[, 1], tfidfs[, 'index']), 'tfidf_score']
input[, 9:10] <- sentiment[match(input[, 1], sentiment[, 'index']), 2:3]
for (i in 1:length(tags)) {
  input <- cbind.data.frame(input, as.numeric(grepl(tags[i], input[, 5])))
}
for (i in 1:length(topics)) {
  input <- cbind.data.frame(input, as.numeric(grepl(topics[i], input[, 6])))
}
input <- cbind.data.frame(input, round(lda.res, 6))
colnames(input) <- c('idx', 'views', 'nchars', 'date', 'tags', 'topics',
                     'dtm', 'tf_idf', 'rel_sent', 'cum_sent',
                     paste('is', tags, sep = '_'),
                     paste('has', topics, sep = '_'),
                     paste('prob_topic', sprintf('%02.0f', 1:ncol(lda.res)),
                           sep = '_'))

# Some extra ex-post columns
input[, 'nwords'] <- unlist(lapply(strsplit(talks[, 'text'], ' '), length))
input[, 'nuwords'] <- unlist(lapply(strsplit(talks[, 'text'], ' '),
  function(x) {
    length(unique(x))
}))
input[, 'time_sec'] <- unlist(lapply(strsplit(talks[, 'duration'], ':'),
  function(x) {
    as.numeric(x[1]) * 60 + as.numeric(x[2])
}))
recurr <- names(table(talks[, 'speaker'])[table(talks[, 'speaker']) > 1])
input[, 'recurrent'] <- as.numeric(talks[, 'speaker'] %in% recurr)

# Kill some non-frequent topics
out <- c('has_in', 'has_for', 'has_per', 'has_ted')
res <- colSums(input[, paste('has', topics, sep = '_')]) / nrow(input)
aux <- res[res >= 0.05]
cols <- names(aux[! names(aux) %in% out])
cols.no <- c(names(res[res < 0.03]), out)
for (col in cols.no) { input[, col] <- NULL }

# Final design matrix for the model
# We count until June 1 2016
ref.date <- as.Date('1 jun 2016', '%d %b %Y')
new.date <- as.Date('30-04-2016', '%d-%m-%Y')
old.date <- as.Date('01-01-2008', '%d-%m-%Y')
new.cols <- c('nchars', 'dtm', 'tf_idf', 'rel_sent', 'cum_sent', 'nwords',
              'nuwords', 'time_sec', 'recurrent',
              paste('is', tags, sep = '_'), cols,
              paste('prob_topic', sprintf('%02.0f', 1:ncol(lda.res)),
                    sep = '_'))

# Adapt columns
design <- as.data.frame(input[, 'views'])
design[, 2] <- log(as.numeric(ref.date - input[, 'date']))
#design[, 3] <- design[, 2] ** 2
colnames(design) <- c('views', 'log_time')
design <- cbind.data.frame(design, input[, new.cols])
design[, 'nchars'] <- log(design[, 'nchars'])
design[, 'nwords'] <- log(design[, 'nwords'])
design[, 'nuwords'] <- log(design[, 'nuwords'])
design[, 'time_sec'] <- log(design[, 'time_sec'])

# Erase potential outliers
design <- design[which(input[, 'date'] < new.date &
                       input[, 'date'] > old.date), ]
design <- design[which(design[, 'views'] > 0), ]
design <- design[which(design[, 'views'] < 2e7), ]
design <- design[which(design[, 'time_sec'] > log(3 * 60)), ]
design <- design[which(design[, 'time_sec'] < log(20 * 60)), ]
design <- design[which(design[, 'nwords'] > log(100)), ]

# # Plot the explained variable
# png('doc/log_normal_dist.png', width = 800, height = 400)
# par(mfrow = c(1, 2))
# plot(density(design$views), main = 'Density distribtution of number of views')
# plot(density(log(design$views)), , main = 'Density distribtution of the log of the number of views')
# dev.off()

# Regression
mod01 <- lm(log(views) ~ ., data = design)
mod02 <- lm(views ~ ., data = design)
mod03 <- lm(log(views) ~ prob_topic_01, data = design)
summary(mod01)
summary(mod02)
summary(mod03)
#summary(lm(formula = views ~ prob_topic_01, data = design))
#summary(lm(views ~ prob_topic_01 + prob_topic_02 + prob_topic_03 + prob_topic_04 + prob_topic_05 + prob_topic_06 + prob_topic_07 + prob_topic_08 + prob_topic_09 + prob_topic_10 + prob_topic_11 + prob_topic_12, data = design))

for (i in 1:12) {
  preds <- sprintf('%02.0f', setdiff(1:12, i))
  cat(rep('*', 80), '\n', sep = '')
  cat('MODEL WITHOUT PREDICTOR:', sprintf('%02.0f', i), '\n')
  cat(rep('*', 80), '\n', sep = '')
  form <- as.formula(paste('log(views) ~',
                     paste(paste('prob_topic', preds, sep = '_'),
                     collapse = ' + ')))
  print(summary(lm(form, data = design)))
  readline('Press <Enter> for next model ')
}

design2 <- design
design2[, 'prob_topic_11'] <- NULL
design2[, 'has_economics'] <- NULL
design2[, 'is_informative'] <- NULL
summary(lm(log(views) ~ ., data = design2))

design2[, 'cum_sent'] <- log(design2[, 'cum_sent'] + abs(min(design2[, 'cum_sent'])) + 1)
cols <- c('log_time', 'time_sec', 'recurrent', 'cum_sent',
          paste('prob_topic', sprintf('%02.0f', setdiff(1:12, 11)), sep = '_'))
form <- as.formula(paste('log(views) ~', paste(cols, collapse = ' + ')))
summary(lm(form, data = design2))

# What!?
if (FALSE) {
  form <- as.formula(paste('log(views) ~ -1 +', paste(cols, collapse = ' + ')))
  summary(lm(form, data = design2))
}

# Standardising y: not helpful
if (FALSE) {
  design2[, 'views'] <- scale(design2[, 'views'])
  form <- as.formula(paste('views ~', paste(cols, collapse = ' + ')))
  summary(lm(form, data = design2))
}

# Almost same results with 1's 0's on probabilities
if (FALSE) {
  # Put 1's and 0's instead of probabilities
  prob.cols <- paste('prob_topic', sprintf('%02.0f', 1:12, 11), sep = '_')
  isolated <- design[, prob.cols]
  maxims <- lapply(1:nrow(isolated), function(x) {
    row <- isolated[x, ]
    y <- rep(0, length(row))
    y[which.max(row)] <- 1
    return(y)
  })
  isolated <- as.data.frame(do.call('rbind', maxims))

  # Substitute and see what happens
  design2[, prob.cols] <- isolated
  summary(lm(form, data = design2))
}






















