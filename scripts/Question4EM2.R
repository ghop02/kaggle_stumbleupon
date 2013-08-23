library(plyr)

Calculate.Expectation <- function(K, data, pis, clusters)
{
  log_pis <- log(pis)
  log_clusters <- log(clusters)
  
  # returns a nrow(data) x K vector
  temp <- t(log_clusters %*% t(data))
  temp <- log_pis + temp
  
  #do log.sum to each row, returning a D vector containing log sums of each row
  logSums <- apply(temp, 1, log.sum)
  
  # Normalize values
  final_log <- temp - logSums
  
  # exponentiate to get back from log space
  final <- exp(final_log)
  
  return(final)
}

Calculate.New.Cluster.Proportions <- function(lambdas)
{  
  return(colSums(lambdas)/nrow(lambdas))
}



Calculate.New.Clusters <- function(lambdas, D, K, wcByDoc)
{
  
  thetas <- matrix(nrow=K, ncol=ncol(D))
  V <- ncol(D)
  x<- rep(0,V)
  for (k in 1:K)
  {
    y <- sum(lambdas[,k]*wcByDoc)
    x <-  colSums(D*lambdas[,k])  
    thetas[k,] <- x/y
  }
  
  return(thetas)
}


# Initialize clusters 
initialize.clusters <- function(K, data)
{
  # create a k x nrows(corp) length matrix to hold clusters
  betas <- matrix(nrow=K, ncol=ncol(data))
  
  # choose k random documents
  D <- sample(1:nrow(data), K)
  
  
  # initialize values 
    betas<- data[D,] + matrix(runif(ncol(data)*length(D)), ncol=ncol(data)) + 10
    betas <- betas / rowSums(betas)
  
  
  
  # Initialize Values to the uniform distribution
#   for (d in D)
#   {
#     betas[i,] <- rep(1/ncol(data), ncol(data))
#     i<- i+1
#   }
  
  return(betas)
}


# Function to calculate Maximum Log-Likelihood estimate
Calculate.MLE <-function(K, D, lambdas, pis, clusters)
{
  return(sum(lambdas*(log(pis) + D %*% t(log(clusters)))))  
}

log.safe<-function(x)
{
  if (x == 0)
    x = 0.000001
  return(log(x))  
}

Run.EM <- function(K, data)
{
  source('log.R')
  
  # All of the "documents"
  D <- data
  
  # Z contains the probabilities that document d is in cluster k
  Z <- matrix(nrow=nrow(D), ncol=K)
  
  # initialize clusters and proportions
  clusters <- initialize.clusters(K, D)
  
  pis <- rep(1/K, K)
  lambdas <- c()
  MLE <- c()
  
  # set the delta_obj to sum value high enough to do things right
  prev <- 1
  dif <- 1
  
  # number of words in each document
  wcByDoc <- rowSums(D)
  
  # run Expectation maximization until change in object is less than .0001
  while (abs(dif) > .0001)

  {
    # calculates the conditional distribution of document d being 
    # in cluster z_k given current setting of pis and theta
    lambdas <- Calculate.Expectation(K, D, pis, clusters)
    
    # Calculate new cluster proportions
    pis <- Calculate.New.Cluster.Proportions(lambdas)
    
    # Calculate new thetas
    clusters <- Calculate.New.Clusters(lambdas, D, K, wcByDoc)
    
    # Calculate new objective function
    cur <- Calculate.MLE(K, D, lambdas, pis, clusters)
    MLE <- c(MLE, cur)
    dif <- (prev - cur)/prev
    prev <- cur
    
  }

  # return relevant results
  return(list("clusters"=clusters,"pis"=pis, "lambdas"=lambdas, "MLE"=MLE))
}


# Writes the 15 most common words from each cluster
View.Most.Common.Words <- function(clusters, vocab, n_docs=NULL)
{
  nWords <- 30
  K <- nrow(clusters)
    
  clusters_sorted <- t(apply(clusters,1, function(x) {return(sort(x,decreasing=TRUE, index.return=TRUE)$ix)}))  

  names <- matrix(nrow=nWords, ncol=K)
  for (i in 1:K)
    names[,i] <- vocab[clusters_sorted[i,1:nWords]]
  
  write(x=n_docs, file='~/kaggle/kaggle_stumbleupon/clusters', sep='\t', append=TRUE, ncolumns=K)
  write(x=t(names), append=TRUE, file='~/kaggle/kaggle_stumbleupon/clusters', sep='\t',ncolumns=K)
  return(names)
}

# Cluster information
View.Cluster.Stats <- function(d) {
 
  data <- d$x
  vocab <- d$vocab
  corp <- d$corp
  
  #number of documents per cluster (highest probability)
  top_cluster_by_doc <-aaply(data$lambdas, 1, which.max)
  n_docs_per_cluster <- table(top_cluster_by_doc)
  
  # find top words for docs in cluster
  # gets the most common words in each cluster
  words <- View.Most.Common.Words(data$clusters, vocab, n_docs=n_docs_per_cluster)
  
  # prints most common words across all documents
  most_common_words <- em$vocab[order(colSums(corp), decreasing=TRUE)][1:100]
  return(list(docs_per_cluster=n_docs_per_cluster, words=words, most_common_words = most_common_words))
}


# Runs EM algorithm on dataset, computes perplexity of that dataset
Run.EM.Experiment <- function()
{
  load('corp1.Rdat')
  D <- corp
  K <- 2
  experiment <- Run.EM(K, D)
  return(experiment)
  
  # compute perplexity of a single document
  perp <- Compute.Perplexity.Doc(D[1,], experiment$clusters, experiment$pis, K)
  
  # perp <- Compute.Perplexity.Doc(c(2,1), t(matrix(c(.25, .75, .75, .25), nrow=2)), c(.5, .5), 2)
  print(perp)
}

# process referrals for jana
Process.Referrals <- function(folder, K=5) {
  corp <- read.csv(paste(folder, '/corpus.csv',sep=''), header=FALSE)
  corp <- corp[1:nrow(corp)-1,]
  words <- read.csv(paste(folder, '/words.csv', sep = ''), header=FALSE)
  vocab <- as.character(t(as.data.frame(words)))
  #print(vocab)
  print(dim(corp))
  print(length(vocab))
  corp <- as.matrix(corp)
  x <- Run.EM(K, corp)
  return(list(x = x, vocab = vocab, corp = corp))
  stats <- View.Cluster.Stats(x, vocab, corp, folder)
  return(list(x = x, vocab = vocab, corp = corp))
}

Process.Country.Referrals <- function(K = 5) {
  countries <- list.dirs('/engagement_analytics/results/')
  country_list <- c('NG', 'IN', 'ID', 'PH', 'BD', 'VN', 'KE', 'ZA', 'BR')
  #country_list <- c('VN', 'KE', 'ZA', 'BR')
  l <- list()
  for (country in country_list) {
    print(country)
    l[[country]] <- Process.Referrals(paste('/engagement_analytics/results/', country, sep = ""), K=K)
  }
  return(l)
}
View.All <- function(d) {
  country_list <- c('NG', 'IN', 'ID', 'PH', 'BD', 'VN', 'KE', 'ZA', 'BR')
  for (country in country_list)
    View.Cluster.Stats(d[[country]], country)
  
}


# runs experiment with five folds, returns average perplexity
Run.Fold.Experiment<- function(K, data)
{
  
  x <- sample(rep(1:5, length=nrow(data)))
  
  perp <- c()
  for (i in 1:5)
  {
    inFold <- data[which(x == i),]
    outFold <- data[which(x != i),]
    experiment <- Run.EM(K, outFold)

    #calculate perplexities on each document
    perp <- c(perp, Compute.Perplexity.Docs(inFold, experiment$clusters, experiment$pis))
  }
  
  return(mean(perp[perp!=Inf]))
}

# Run all fold experiment
Run.Fold.Experiments<-function()
{
  Ks <- c(2, 5, 10, 20, 30)
  
  load('corp1.Rdat')
  for (k in Ks)
  {
    print(paste(k, " ", Run.Fold.Experiment(k, corp)), quotes=FALSE)
  }
  
  load('corp2.Rdat')
  for (k in Ks)
  {
    print(paste(k, " ", Run.Fold.Experiment(k, corp)), quotes=FALSE)
  }  
}



# compute perlexity of doc
Compute.Perplexity.Docs<-function(data, clusters, pis)
{
  
  log_pis <- log(pis)
  log_clusters <- log(clusters)
  
  
  # returns an nrow(data) x K vector
  
  temp <- t(log_clusters %*% t(data))
  temp <- log_pis + temp
  
  #do log.sum to each row, returning a D vector containing log sums of each row
  logSums <- apply(temp, 1, log.sum)
  
  # exponentiate to get back from log space
  final <- exp(logSums)
  log2Final <- log2(final)
  
  #perplexity <- 2^(-log2(final)/as.integer(rowSums(data)))
  perplexity <- 2^(-log2Final/as.integer(rowSums(data)))
  
  return(matrix(perplexity, nrow=1))
}

safe.log2<-function(x)
{
  if (x==0)return(-1000)
  else return(log2(x))
  
}
