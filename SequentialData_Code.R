library(TraMineR)
library(TraMineRextras)
library(PST)
library(stringr)
library(cluster)
library(WeightedCluster)

# Part 1: 

# 1. DEFINING THE SAMPLE FOR PEOPLE.
setwd("/Users/ali/Desktop/Sequential Data") 
file <- read.csv("file_to_be_formatted.csv")
data <- data.frame(file)
data <- file[c(17:115),]
data_seq <- data[,c(4,7,10)]
data_seq_t <- t(data_seq)

# 2. CREATING A LIST OF SEQUENCES USING PROBABILISTIC SUFFIX TREE.
data_seq_s <- seqdef(data_seq_t)
data_seq_pst <- pstree(data_seq_s, ymin = 0.001, lik = FALSE, with.missing = FALSE, nmin = 2, L = 7)
print(data_seq_pst)
plot(data_seq_pst)

# 3. PRUNE THE TREE
C99 <- qchisq(0.99, 1)/2
data_tune <- tune(data_seq_pst, gain="G1", C=C99, output = "stats", criterion = "AICc") 
data_seq_pst_prune <- prune(data_seq_pst, gain="G1", C=C99, delete=TRUE, lik=TRUE)
summary(data_seq_pst_prune)


# Part 2:

# 1. GENERATE CLUSTERS
data_seq_states <- c("1", "2", "3", "4", "5", "6", "7")
data_seq_cm <- cmine(data_seq_pst_prune, pmin = 0, state = data_seq_states)
data_seq_cm_output <- list()
for (i in 1:length(data_seq_cm)){
  data_seq_cm_output[i] <- data_seq_cm[[i]]@context
}  
fdata_sequences <- unlist(data_seq_cm_output)
fdata_sequences <- fdata_sequences[str_detect(fdata_sequences, "-")]

final_data <- seqdef(fdata_sequences)

final_ccost <- seqsubm(final_data, method = "CONSTANT", cval = 2)
final_data_om <- seqdist(final_data, method = "OM", sm = final_ccost, indel = 2)

final_clusterward <- agnes(final_data_om, diss = TRUE, method = "ward")
pltree(final_clusterward, cex = 0.6, hang = -1, main = "Dendrogram of agnes") 

# 2. CLUSTER QUALITY
(final_agnesRange <- wcKMedRange(final_data_om, 2:10))
plot(final_agnesRange, stat = c("PBC", "HG", "ASW"), lwd = 3)

final_n_clusters <- 3
final_pattern <- cutree(as.hclust(final_clusterward), k = final_n_clusters)

final_clus_1 <- fdata_sequences[which(final_pattern==1)]
final_clus_2 <- fdata_sequences[which(final_pattern==2)]
final_clus_3 <- fdata_sequences[which(final_pattern==3)]

final_clus1 <- seqdef(final_clus_1)
seqstatf(final_clus1)
final_clus2 <- seqdef(final_clus_2)
seqstatf(final_clus2)
final_clus3 <- seqdef(final_clus_3)
seqstatf(final_clus3)

final_ccost1 <- seqsubm(final_clus1, method = "CONSTANT", cval = 2)
final_cluster1_om <- seqdist(final_clus1, method = "OM", norm = TRUE, sm = final_ccost1, indel = 2)
final_ccost2 <- seqsubm(final_clus2, method = "CONSTANT", cval = 2)
final_cluster2_om <- seqdist(final_clus2, method = "OM", norm = TRUE, sm = final_ccost2, indel = 2)
final_ccost3 <- seqsubm(final_clus3, method = "CONSTANT", cval = 2)
final_cluster3_om <- seqdist(final_clus3, method = "OM", norm = TRUE, sm = final_ccost3, indel = 2)

final_cluster1_rep <- seqrep(final_clus1, diss = final_cluster1_om, criterion = "dist", nrep = nrow(final_clus1))
final_cluster1_rep <- seqconc(final_cluster1_rep)
final_cluster2_rep <- seqrep(final_clus2, diss = final_cluster2_om, criterion = "dist", nrep = nrow(final_clus2))
final_cluster2_rep <- seqconc(final_cluster2_rep)
final_cluster3_rep <- seqrep(final_clus3, diss = final_cluster3_om, criterion = "dist", nrep = nrow(final_clus3))
final_cluster3_rep <- seqconc(final_cluster3_rep)

final_cluster1_rep.top4 <- seqrep(final_clus1, diss = final_cluster1_om, criterion = "dist", nrep = 4)
final_cluster1_rep.top4 <- seqconc(final_cluster1_rep.top4)
final_cluster2_rep.top4 <- seqrep(final_clus2, diss = final_cluster2_om, criterion = "dist", nrep = 4)
final_cluster2_rep.top4 <- seqconc(final_cluster2_rep.top4)
final_cluster3_rep.top4 <- seqrep(final_clus3, diss = final_cluster3_om, criterion = "dist", nrep = 4)
final_cluster3_rep.top4  <- seqconc(final_cluster3_rep.top4)

Top4_rep_set <- cbind(final_cluster1_rep.top4,final_cluster2_rep.top4,final_cluster3_rep.top4)
colnames(Top4_rep_set)[1] <- "Cluster 1"
colnames(Top4_rep_set)[2] <- "Cluster 2"
colnames(Top4_rep_set)[3] <- "Cluster 3"
View(Top4_rep_set)

# 3. CHOOSE NUMBER OF CLUSTERS BASED ON QUALITY EVALUATION.

# Part 3:

# 1. Based on the cluster generated, check the distribution of frequencies across clusters.

cluster_1_10 <- list(0)
cluster_1_20 <- list(0)
cluster_1_50 <- list(0)
cluster_2_10 <- list(0)
cluster_2_20 <- list(0)
cluster_2_50 <- list(0)
cluster_3_10 <- list(0)
cluster_3_20 <- list(0)
cluster_3_50 <- list(0)

X2.seq <- seqdef(data_seq[1,])
X5.seq <- seqdef(data_seq[2,])
X8.seq <- seqdef(data_seq[3,])
X2.seq <- t(X2.seq)
X5.seq <- t(X5.seq)
X8.seq <- t(X8.seq)
X2_seq <- seqdef(X2.seq)
X5_seq <- seqdef(X5.seq)
X8_seq <- seqdef(X8.seq)

for (i in 1:nrow(final_cluster1_rep)) 
{
  cluster_1_10[i] <- seqpm(X2_seq, final_cluster1_rep[i], sep = "-")
  cluster_1_20[i] <- seqpm(X5_seq, final_cluster1_rep[i], sep = "-")
  cluster_1_50[i] <- seqpm(X8_seq, final.cluster1_rep[i], sep = "-")
}

for (i in 1:nrow(final_cluster2_rep)) 
{
  cluster_2_10[i] <- seqpm(X2_seq, final_cluster2_rep[i], sep = "-")
  cluster_2_20[i] <- seqpm(X5_seq, final_cluster2_rep[i], sep = "-")
  cluster_2_50[i] <- seqpm(X8_seq, final_cluster2_rep[i], sep = "-")
}
for (i in 1:nrow(final_cluster3_rep)) 
{
  cluster_3_10[i] <- seqpm(X2_seq, final_cluster3_rep[i], sep = "-")
  cluster_3_20[i] <- seqpm(X5_seq, final_cluster3_rep[i], sep = "-")
  cluster_3_50[i] <- seqpm(X8_seq, final_cluster3_rep[i], sep = "-")
}

# 2. Determine how each cluster performs in respective frequencies.

cluster1_quality <- do.call(rbind.data.frame, Map('c', cluster_1_10, cluster_1_20, cluster_1_50))
cluster2_quality <- do.call(rbind.data.frame, Map('c', cluster_2_10, cluster_2_20, cluster_2_50))
cluster3_quality <- do.call(rbind.data.frame, Map('c', cluster_3_10, cluster_3_20, cluster_3_50))
Total_10Events = sum(cluster1_quality$nbocc) +sum(cluster2_quality$nbocc) + sum(cluster3_quality$nbocc)
Total_20Events = sum(cluster1_quality$nbocc.1) + sum(cluster2_quality$nbocc.1) + sum(cluster3_quality$nbocc.1)
Total_50Events = sum(cluster1_quality$nbocc.2) + sum(cluster2_quality$nbocc.2) + sum(cluster3_quality$nbocc.2)
cluster1_quality$Ten_Percentage <- cluster1_quality$nbocc/Total_10Events*100
cluster1_quality$Twenty_Percentage <- cluster1_quality$nbocc.1/Total_20Events*100
cluster1_quality$Fifty_Percentage <- cluster1_quality$nbocc.2/Total_50Events*100
toString(cluster1_quality$pattern)
cluster2_quality$Ten_Percentage <- cluster2_quality$nbocc/Total_10Events*100
cluster2_quality$Twenty_Percentage <- cluster2_quality$nbocc.1/Total_20Events*100
cluster2_quality$Fifty_Percentage <- cluster2_quality$nbocc.2/Total_50Events*100
cluster3_quality$Ten_Percentage <- cluster3_quality$nbocc/Total_10Events*100
cluster3_quality$Twenty_Percentage <- cluster3_quality$nbocc.1/Total_20Events*100
cluster3_quality$Fifty_Percentage <- cluster3_quality$nbocc.2/Total_50Events*100

