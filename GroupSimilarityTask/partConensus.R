#alejandro catacora
#1/7/2024
#partConcensus.R
#upload and read two small data clusters to get consensus patterns
#just looking at the individual cluster to get thier respective weighted and consensus pattern
library(tidyverse)
library(approxmapR)

#read csv file
sequences <- read.csv("7seqDataset.csv")

#aggregate by month
agg <- sequences %>%
  aggregate_sequences(format = "%m/%d/%Y", unit = "month", n_units = 1, summary_stats = FALSE)

#make sure its just looking at one cluster
clustered_data <- agg %>%
  cluster_knn(k = 2)

#extract consensus pattern from cluster
consensus_patterns <- clustered_data %>%
  filter_pattern(threshold = 0.4, pattern_name = "consensus")
#format the result 
formatted_results <- consensus_patterns %>%
  format_sequence(compare = TRUE)

print(formatted_results)