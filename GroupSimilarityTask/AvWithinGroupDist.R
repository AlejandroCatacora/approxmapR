#Alejandro Catacora
#1/20/2024
#Using approxmap, runs two datasets (original and the oppositedatasets created) to find the avg within group distance



library(approxmapR)
library(tidyverse)

process_sequences <- function(file_path) {
  sequences <- read.csv(file_path)
  sequences <- sequences %>%
    mutate(item = strsplit(as.character(item), "")) %>%
    unnest(item) %>%
    filter(item != "", !is.na(item))

  agg <- sequences %>%
    aggregate_sequences(format = "%m/%d/%Y", unit = "month", n_units = 1, summary_stats = FALSE)
  
  clustered_data <- agg %>%
    cluster_kmedoids(k = 2)
  
  consensus_patterns <- clustered_data %>%
    filter_pattern(threshold = 0.4, pattern_name = "consensus")
  
  sequences_with_gaps <- seqs(consensus_patterns$weighted_sequence)
  aligned_consensus_patterns <- consensus(consensus_patterns, consensus_patterns$weighted_sequence)
  
  return(list(sequences_with_gaps = sequences_with_gaps, aligned_consensus = aligned_consensus_patterns))
}


#get item set with gaps for all seqs
seqs <- function(weighted_sequence) {
  sequences_output <- list()
  for (cluster_idx in seq_along(weighted_sequence)) {
    cluster_sequences <- list()
    cluster <- weighted_sequence[[cluster_idx]]
    if ("alignments" %in% names(attributes(cluster))) {
      alignments <- attr(cluster, "alignments")
      sequence_ids <- names(alignments)
      
      for (seq_idx in seq_along(alignments)) {
        sequence_vector <- sapply(alignments[[seq_idx]], function(itemset) {
          if (is.character(itemset) && all(itemset == "_")) {
            return(NA)  
          } else {
            return(paste(itemset, collapse=""))
          }
        })
        cluster_sequences[[sequence_ids[seq_idx]]] <- sequence_vector
      }
    } else {
      cluster_sequences <- "No alignments data found."
    }
    sequences_output[[paste0("Cluster ", cluster_idx)]] <- cluster_sequences
  }
  return(sequences_output)
}

#get consensus with gaps using weighted seq
consensus <- function(consensus_patterns, weighted_sequences) {
  consensus_output <- list()
  for (cluster_idx in seq_along(consensus_patterns$consensus_pattern)) {
    consensus_list <- consensus_patterns$consensus_pattern[[cluster_idx]]
    weighted_seq_cluster <- weighted_sequences[[cluster_idx]]
    aligned_consensus <- vector("list", length(weighted_seq_cluster))
    cons_idx <- 1
    
    for (ws_idx in seq_along(weighted_seq_cluster)) {
      if (cons_idx > length(consensus_list)) {
        aligned_consensus[ws_idx] <- NA 
      } else {
        consensus_itemset <- consensus_list[[cons_idx]]$elements
        weighted_seq_itemset <- weighted_seq_cluster[[ws_idx]]$elements
        
        if (all(consensus_itemset %in% weighted_seq_itemset)) {
          aligned_consensus[ws_idx] <- paste(consensus_itemset, collapse="")
          cons_idx <- cons_idx + 1
        } else {
          aligned_consensus[ws_idx] <- NA
        }
      }
    }
    aligned_consensus_vector <- unlist(aligned_consensus)
    consensus_output[[paste0("Cluster ", cluster_idx)]] <- aligned_consensus_vector
  }
  return(consensus_output)
}

#levenshteins distance calcualtion
distance <- function(seq, cons) {
  levenshtein <- function(seq, cons) {
    element_wise_averages <- numeric(length(cons))
    valid_indices <- which(cons != "") #empty itemset
    
    for (i in valid_indices) {
      elements <- sapply(seq, function(s) ifelse(length(s) >= i, s[i], ""))
      distances <- sapply(elements, stringdist, cons[i], method = "lv")
      element_wise_averages[i] <- mean(distances, na.rm = TRUE)
    }
    
    #filter out NA's
    filtered_averages <- element_wise_averages[valid_indices]
    print(filtered_averages)
    return(filtered_averages)
  }
  
  #avg distance for individual
  element_wise_averages <- levenshtein(seq, cons)
  
  overall_average_distance <- mean(element_wise_averages, na.rm = TRUE)
  print(overall_average_distance)
  return(list(element_wise_averages = element_wise_averages, overall_average_distance = overall_average_distance))
}

#process Datasets A and B
result_A <- read.csv("originalDataset.csv")
result_B <- read.csv("oppositeDataset.csv")

#calculate Levenshtein Distance for each cluster 
A1 <- distance(result_A$sequences_with_gaps[[1]], result_A$aligned_consensus[[1]])
A2 <- distance(result_A$sequences_with_gaps[[2]], result_A$aligned_consensus[[2]])

B1 <- distance(result_B$sequences_with_gaps[[1]], result_B$aligned_consensus[[1]])
B2 <- distance(result_B$sequences_with_gaps[[2]], result_B$aligned_consensus[[2]])

#average distance 
A_avg <- (A1$overall_average_distance + A2$overall_average_distance) / 2
B_avg <- (B1$overall_average_distance + B2$overall_average_distance) / 2
withinDist <- (A_avg + B_avg) / 2

print(withinDist)

