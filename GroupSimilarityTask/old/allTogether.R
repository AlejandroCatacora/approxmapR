#all together to see results from changing the data

#install.packages("approxmapR")
#install.packages("devtools")
#install.packages("glue")
#install.packages("tidyverse")

library(approxmapR)
library(devtools)
library(glue)
library(tidyverse)

#creating dataset on monthy employment status
create_synthetic_dataset <- function(set_seed, num_individuals, events) {
  set.seed(set_seed)
  periods_per_individual <- sample(3:12, num_individuals, replace = TRUE)
  
  dataset <- map_df(1:num_individuals, ~tibble(
    id = .x,
    period = seq(from = as.Date('1993-01-01'), by = "month", length.out = periods_per_individual[.x]),
    event = sample(events, periods_per_individual[.x], replace = TRUE, prob = runif(length(events)))  #randomized probabilities
  ))
  
  return(dataset)
}


# Create synthetic datasets A and B
dataset_A <- create_synthetic_dataset(123, 20, c("employed", "unemployed", "education", "other"))
dataset_B <- create_synthetic_dataset(124, 20, c("employed", "unemployed", "education", "other"))



#define the function to run approxmapR
run_approxmap <- function(dataset) {
  dataset %>%
    arrange(id, period) %>%
    mutate(
      event = str_to_lower(event),
      #convert 'period' to character
      period = as.character(period)
    ) %>%
    aggregate_sequences(format = "%Y-%m-%d", unit = "month", n_units = 1) %>%
    cluster_knn(k = 3) %>%
    filter_pattern(threshold = 0.5, pattern_name = "consensus") %>%
    filter_pattern(threshold = 0.3, pattern_name = "variation")
}

#run approxmap 
patterns_A <- run_approxmap(dataset_A)
patterns_B <- run_approxmap(dataset_B)





#use existing functions from your script
extract_seqs <- function(pats) {
  pats %>% pull(df_sequences) %>% map(~ .x$sequence) %>% unlist()
}

extract_cons <- function(pats) {
  pats %>% pull(consensus_pattern) %>% map_chr(~ paste(.x$elements, collapse = " "))
}

#function to calculate within-group distance
calc_within_group_dist <- function(seqs, cons) {
  sapply(seqs, function(seq) {
    if (is.character(seq) && is.character(cons)) {
      stringdist::stringdist(seq, cons, method = "lv")
    } else {
      Inf  #high distance if types are not matching
    }
  }) %>% mean(na.rm = TRUE)
}






#shorten function to find the closest consensus sequence
find_closest_cons <- function(seqs, cons_group) {
  sapply(seqs, function(seq) {
    dists <- sapply(cons_group, function(cons) {
      if (is.character(seq) && is.character(cons)) {
        stringdist::stringdist(seq, cons, method = "lv")
      } else {
        Inf  #high distance if types are not matching
      }
    })
    if (is.numeric(dists)) {
      min(dists, na.rm = TRUE)
    } else {
      Inf  #high distance if dists is not numeric
    }
  })
}

#shorten function to calculate between-group distance
calc_between_group_dist <- function(seq_A, cons_B, seq_B, cons_A) {
  dist_A_to_B <- find_closest_cons(seq_A, cons_B)
  dist_B_to_A <- find_closest_cons(seq_B, cons_A)
  
  avg_dist_A <- mean(dist_A_to_B, na.rm = TRUE)
  avg_dist_B <- mean(dist_B_to_A, na.rm = TRUE)
  
  (avg_dist_A + avg_dist_B) / 2
}


# Calculate group similarity with a tolerance for floating point precision
calculate_group_similarity <- function(within_dist, between_dist, tolerance = 1e-10) {
  if (abs(within_dist - between_dist) < tolerance) {
    return(0)
  } else {
    return((between_dist - within_dist) / within_dist)
  }
}

seqs_A <- extract_seqs(patterns_A)
seqs_B <- extract_seqs(patterns_B)
cons_A <- extract_cons(patterns_A)
cons_B <- extract_cons(patterns_B)

#calculate within-group distances for A and B
within_dist_A <- calc_within_group_dist(seqs_A, cons_A)
within_dist_B <- calc_within_group_dist(seqs_B, cons_B)

#calculate the overall average within-group distance
overall_within_dist <- (within_dist_A + within_dist_B) / 2



#calculate and print overall between-group distance
overall_dist <- calc_between_group_dist(seqs_A, cons_B, seqs_B, cons_A)

# Calculate group similarity
group_similarity <- calculate_group_similarity(overall_within_dist, overall_dist)




#print the overall average within-group distance
print(glue::glue("Overall within-group distance: {overall_within_dist}"))
print(glue::glue("Overall between distance: {overall_dist}"))
print(glue::glue("Group Similarity: {group_similarity}"))



