#Alejandro Catacora
#Dec 25,2023
#1.A : Run approxMap on each group seperately: conseq for A

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
dataset_A <- create_synthetic_dataset(123, 15, c("employed", "unemployed", "education", "other"))
dataset_B <- create_synthetic_dataset(124, 15, c("employed", "unemployed", "education", "other"))



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

#run approxmap on dataset A
patterns_A <- run_approxmap(dataset_A)
print(patterns_A)

#run approxmap on dataset B
patterns_B <- run_approxmap(dataset_B)
print(patterns_B)
