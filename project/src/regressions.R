################################################################################
# Dependencies
library(stargazer)

# Working directory
PATH <- '~/Desktop/tm_ted/'
setwd(PATH)

# LIST OF TOPICS table
# Topic 00: society       : year women life day live school time peopl
# Topic 01: environment   : water food year anim ocean speci fish plant
# Topic 02: arts          : music play art applaus laughter book sound word
# Topic 03: biology       : brain bodi human anim differ show move neuron
# Topic 04: universe      : year time earth planet univers light space life
# Topic 05: entertainment : know laughter peopl think littl time actual lot
# Topic 06: politics      : peopl war world state countri polit govern power
# Topic 07: technology    : comput technolog actual data inform work time world
# Topic 08: urbanisation  : citi build design car energi work water place
# Topic 09: economics     : peopl year world countri percent need dollar money
# Topic 10: philosophy    : think peopl know human differ question time mean
# Topic 11: health        : cell diseas patient cancer health drug actual year
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
talks[, 'tags'] <- gsub('Jaw-dropping', 'Jaw_dropping', talks[, 'tags'])

# Tags
tags <- readLines(file3); cat('Read file:', file3, '\n')
tags <- sort(unlist(strsplit(tags, ',')))
tags <- gsub('jaw-dropping', 'jaw_dropping', tags)

# Topics
topics <- readLines(file5); cat('Read file:', file5, '\n')
topics <- sort(unlist(strsplit(topics, ',')))

# Document Term Matrix score
dtms <- read.csv(file = file1); cat('Read file:', file1, '\n')
dtms <- dtms[order(dtms[, 1] + 1, decreasing = FALSE), ]
dtms[, 1] <- dtms[, 1] + 1
rownames(dtms) <- NULL

# TF-IDF score
tfidfs <- read.csv(file = file6); cat('Read file:', file6, '\n')
tfidfs <- tfidfs[order(tfidfs[, 1] + 1, decreasing = FALSE), ]
tfidfs[, 1] <- tfidfs[, 1] + 1
rownames(tfidfs) <- NULL

# Sentiment
sentiment <- read.csv(file = file4); cat('Read file:', file4, '\n')
sentiment[, 1] <- sentiment[, 1] + 1

# LDA Results
lda.res <- read.csv(file = file2); cat('Read file:', file2, '\n')
tt <- round(table(unlist(apply(lda.res, 1, which.max))) / nrow(lda.res), 3)
tops <- as.factor(paste(100 * tt, '%', sep = ''))
names(tops) <- sprintf('%02.0f', as.numeric(names(tt)) - 1)
cat('Distribution of topics:\n')
print(tops)
topic.labs <- c('Society', 'Arts', 'Health', 'Universe', 'Environment',
                'Politics', 'Economy', 'Entertainment', 'Intelligence',
                'Philosophy', 'Performance', 'Technology')

# For report
plda.res <- lda.res
colnames(plda.res) <- topic.labs
title <- 'Correlation plot of the probabilities of LDA Topics (document level)'
png('doc/lda_probs.png', height = 500, width = 500)
corrplot::corrplot(cor(plda.res), mar = c(0, 0, 1, 0), title = title) 
dev.off()
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
input[, 'duration_sec'] <- unlist(lapply(strsplit(talks[, 'duration'], ':'),
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
cols.no <- c(names(res[res < 0.05]), out)
for (col in cols.no) { input[, col] <- NULL }

# Final design matrix for the model
# We count until June 1 2016
ref.date <- as.Date('1 jun 2016', '%d %b %Y')
new.date <- as.Date('30-04-2016', '%d-%m-%Y')
old.date <- as.Date('01-01-2008', '%d-%m-%Y')
new.cols <- c('nchars', 'dtm', 'tf_idf', 'rel_sent', 'cum_sent', 'nwords',
              'nuwords', 'duration_sec', 'recurrent',
              paste('is', tags, sep = '_'), cols,
              paste('prob_topic', sprintf('%02.0f', 1:ncol(lda.res)),
                    sep = '_'))

# Matrix for the model
design <- as.data.frame(input[, 'views'])
design[, 2] <- log(as.numeric(ref.date - input[, 'date']))
#design[, 3] <- design[, 2] ** 2
colnames(design) <- c('views', 'log_time')
design <- cbind.data.frame(design, input[, new.cols])
design[, 'log_dtm'] <- log(design[, 'dtm'])
design[, 'log_tfidf'] <- log(design[, 'tf_idf'])
design[, 'log_nchars'] <- log(design[, 'nchars'])
design[, 'log_nwords'] <- log(design[, 'nwords'])  # keep
design[, 'log_nuwords'] <- log(design[, 'nuwords'])
design[, 'log_duration_sec'] <- log(design[, 'duration_sec'])  # keep

# Erase potential outliers
design <- design[which(input[, 'date'] < new.date &
                       input[, 'date'] > old.date), ]  # 204
design <- design[which(design[, 'views'] > 0), ]  # 0
design <- design[which(design[, 'views'] < 2e7), ]  # 3
design <- design[which(design[, 'duration_sec'] > 3 * 60), ]  # 12
design <- design[which(design[, 'duration_sec'] < 20 * 60), ]  # 155
design <- design[which(design[, 'nwords'] > 100), ]  # 7

# Erase the deprecated columns
design[, 'dtm'] <- NULL
design[, 'tf_idf'] <- NULL
design[, 'nchars'] <- NULL
design[, 'nwords'] <- NULL
design[, 'nuwords'] <- NULL
design[, 'duration_sec'] <- NULL
# corrplot::corrplot(cor(design))

# Plot the explained variable
xlab1 <- 'Number of visualisations'
xlab2 <- 'Natural logarithm of the number of visualisations'
title1 <- 'Distribution of number of views'
title2 <- 'Distribtution of the log of the number of views'
png('doc/log_normal_dist.png', width = 1000, height = 400)
par(mfrow = c(1, 2))
hist(design[, 'views'], breaks = 150, xlab = xlab1, main = title1, col = 'darkblue')
#plot(density(design[, 'views']), main = 'Density distribtution of number of views')
hist(log(design[, 'views']), breaks = 150, xlab = xlab2, main = title2, col = 'darkblue')
#plot(density(log(design[, 'views'])), main = title2)
dev.off()
################################################################################

################################################################################
# Regressions
mod01 <- lm(log(views) ~ ., data = design)
mod02 <- lm(views ~ ., data = design)
mod03 <- lm(log(views) ~ prob_topic_02, data = design)
summary(mod01)
summary(mod02)
summary(mod03)
#summary(lm(formula = views ~ prob_topic_01, data = design))
#summary(lm(views ~ prob_topic_01 + prob_topic_02 + prob_topic_03 + prob_topic_04 + prob_topic_05 + prob_topic_06 + prob_topic_07 + prob_topic_08 + prob_topic_09 + prob_topic_10 + prob_topic_11 + prob_topic_12, data = design))

# Choice of LDA reference topic
if (FALSE) {
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
}

# Choose tag reference
if (FALSE) {
  for (tag in tags) {
    preds <- paste('is', setdiff(tags, tag), sep = '_')
    cat(rep('*', 80), '\n', sep = '')
    cat('MODEL WITHOUT PREDICTOR:', tag, '\n')
    cat(rep('*', 80), '\n', sep = '')
    form <- as.formula(paste('log(views) ~', paste(preds, collapse = ' + ')))
    print(summary(lm(form, data = design)))
    readline('Press <Enter> for next model ')
  }
}

# Choose topic reference (NO NEED)
if (FALSE) {
  form <- as.formula(paste('log(views) ~', paste(cols, collapse = ' + ')))
  print(summary(lm(form, data = design)))
  for (topic in cols) {
    preds <- setdiff(cols, topic)
    cat(rep('*', 80), '\n', sep = '')
    cat('MODEL WITHOUT PREDICTOR:', topic, '\n')
    cat(rep('*', 80), '\n', sep = '')
    form <- as.formula(paste('log(views) ~', paste(preds, collapse = ' + ')))
    print(summary(lm(form, data = design)))
    readline('Press <Enter> for next model ')
  }
}

# New approach
design2 <- design
design2[, 'prob_topic_04'] <- NULL  # Reference topic
design2[, 'is_inspiring'] <- NULL  # Reference tag
design2[, 'log_nchars'] <- NULL  # Super correlated predictors
design2[, 'log_nuwords'] <- NULL  # Super correlated predictors
#design2[, 'log_duration_sec'] <- NULL  # Super correlated predictors
design2[, 'has_issues'] <- NULL  # This is "global issues"
design2[, 'rel_sent'] <- NULL
summary(lm(log(views) ~ ., data = design2))
#summary(lm(log(views) ~ ., data = design2[, c(1, 6:14)]))

# Duration, words, chars, not significant
if (FALSE) {
  design2[, 'cum_sent'] <- log(design2[, 'cum_sent'] + abs(min(design2[, 'cum_sent'])) + 1)
  cols <- c('log_time', 'log_nwords', 'recurrent', 'cum_sent',
            paste('prob_topic', sprintf('%02.0f', setdiff(1:12, 1)), sep = '_'))
  form <- as.formula(paste('log(views) ~', paste(cols, collapse = ' + ')))
  summary(lm(form, data = design2))
  #names(coef(lm(log(views) ~ ., data = design2)))
}

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

# Bayesian variable selection
if (FALSE) {
  library(mombf)
  y <- log(design2[, 'views'])
  x <- design2[, 2:ncol(design2)]
  priorCoef <- zellnerprior(tau = nrow(x))
  ms.unif <- modelSelection(y = y, x = x, priorCoef = priorCoef,
                            priorDelta = modelunifprior(), niter = 10 ** 5)
  ms.bbin <- modelSelection(y = y, x = x, priorCoef = priorCoef,
                            priorDelta = modelbbprior(), niter = 10 ** 5)

  res01 <- postProb(ms.unif)[1:5, ]
  res02 <- postProb(ms.bbin)[1:5, ]

  regs01 <- as.numeric(unlist(strsplit(as.character(res01[1, 'modelid']), ',')))
  regs02 <- as.numeric(unlist(strsplit(as.character(res02[1, 'modelid']), ',')))
  sel01 <- colnames(design2)[1 + regs01]
  sel02 <- colnames(design2)[1 + regs02]
  f01 <- as.formula(paste('log(views) ~', paste(sel01, collapse = ' + ')))
  f02 <- as.formula(paste('log(views) ~', paste(sel02, collapse = ' + ')))
  #summary(lm(log(views) ~ ., data = design2))
  summary(lm(f01, data = design2))
  summary(lm(f02, data = design2))

  aux03 <- paste(as.character(res01[1:5, 'modelid']), collapse = ',')
  aux04 <- paste(as.character(res02[1:5, 'modelid']), collapse = ',')
  reg03 <- sort(unique(as.numeric(unlist(strsplit(aux03, ',')))))
  reg04 <- sort(unique(as.numeric(unlist(strsplit(aux04, ',')))))
  sel03 <- colnames(design2)[1 + reg03]
  sel04 <- colnames(design2)[1 + reg04]
  f03 <- as.formula(paste('log(views) ~', paste(sel03, collapse = ' + ')))
  f04 <- as.formula(paste('log(views) ~', paste(sel04, collapse = ' + ')))
  #summary(lm(log(views) ~ ., data = design2))
  summary(lm(f03, data = design2))
  summary(lm(f04, data = design2))
}

# Final model (is_ingenious, prob_topic_04)
cols <- c('log_time', 'log_duration_sec', 'recurrent', 'log_dtm', 'log_tfidf',
          'log_nwords', 'cum_sent',  'prob_topic_01', 'prob_topic_02',
          #'log_nwords', 'rel_sent',  'prob_topic_01', 'prob_topic_02',
          'prob_topic_03', 'prob_topic_05', 'prob_topic_06', 'prob_topic_07',
          'prob_topic_08', 'prob_topic_09', 'prob_topic_10', 'prob_topic_11',
          'prob_topic_12', 'is_beautiful', 'is_courageous', 'is_fascinating',
          'is_funny', 'is_inspiring', 'is_jaw_dropping', 'is_persuasive',
          'has_ai', 'has_art', 'has_biology', 'has_brain', 'has_business',
          'has_change', 'has_conference', 'has_creativity', 'has_culture',
          'has_design', 'has_economics', 'has_education', 'has_entertainment',
          'has_fellows', 'has_global', 'has_health', 'has_invention',
          'has_medicine', 'has_men', 'has_music', 'has_politics',
          'has_science', 'has_social', 'has_technology', 'has_war')

# Model with everything
recipe <- as.formula(paste('log(views) ~', paste(cols, collapse = ' + ')))
fmodel <- lm(recipe, data = design)
(sfmdoel <- summary(fmodel))

# Start pruning
out <- c('is_beautiful', 'is_courageous', 'is_persuasive', 'has_biology',
         'has_creativity', 'has_economics', 'has_education',
         'has_entertainment', 'has_fellows', 'has_health',
         'has_invention', 'has_medicine', 'has_men', 'has_social')
cols <- cols[! cols %in% out]
recipe <- as.formula(paste('log(views) ~', paste(cols, collapse = ' + ')))
model <- lm(recipe, data = design)
(summod <- summary(model))

# Simple model
scols <- c('prob_topic_01', 'prob_topic_02', 'prob_topic_03', 'prob_topic_05',
           'prob_topic_06', 'prob_topic_07', 'prob_topic_08', 'prob_topic_09',
           'prob_topic_10', 'prob_topic_11', 'prob_topic_12')
recipe <- as.formula(paste('log(views) ~', paste(scols, collapse = ' + ')))
smodel <- lm(recipe, data = design)
(sumsmod <- summary(smodel))

latex.table <- stargazer(smodel, model, fmodel,
                         no.space = TRUE, align = TRUE, single.row = TRUE)

# # Polish LDA reference topic
# if (FALSE) {
#   for (i in 1:12) {
#     kill <- paste('prob_topic', sprintf('%02.0f', i), sep = '_')
#     preds <- setdiff(cols, kill)
#     cat(rep('*', 80), '\n', sep = '')
#     cat('MODEL WITHOUT PREDICTOR:', kill, '\n')
#     cat(rep('*', 80), '\n', sep = '')
#     form <- as.formula(paste('log(views) ~', paste(preds, collapse = ' + ')))
#     print(summary(lm(form, data = design)))
#     readline('Press <Enter> for next model ')
#   }
# }








