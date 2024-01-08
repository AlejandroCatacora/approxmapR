#alejandro catacora
#1/7/2024
#repConcensus.r
#input the whole 10seq data example, sort excel data and run through approxmap to get consensus from each cluster found

library(approxmapR)
library(tidyverse)

sequences <- read.csv("10seqDataset.csv")

#clean dataset
sequences <- sequences %>%
  mutate(item = strsplit(as.character(item), "")) %>% #split string 
  unnest(item) %>% #seperate double characters
  filter(item != "", !is.na(item)) #remove empty items 

#aggregate sequence by month
agg <- sequences %>%
  aggregate_sequences(format = "%m/%d/%Y", unit = "month", n_units = 1, summary_stats = FALSE)

clustered_data <- agg %>%
  cluster_kmedoids(k = 2)

#extract consensus patterns
consensus_patterns <- clustered_data %>%
  filter_pattern(threshold = 0.4, pattern_name = "consensus")

#format the result 
formatted_results <- consensus_patterns %>%
  format_sequence(compare = TRUE)
print(formatted_results)