#Alejandro Catacora
#Dec 25,2023
#1.C : Calculate within Group
#draft 1
library(tidyverse)
library(approxmapR)
library(stringdist)

#shorten function to extract sequences
extract_seqs <- function(pats) {
  pats %>% pull(df_sequences) %>% map(~ .x$sequence) %>% unlist()
}

#shorten function to extract and format consensus sequences
extract_cons <- function(pats) {
  pats %>% pull(consensus_pattern) %>% map_chr(~ paste(.x$elements, collapse = " "))
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

#assuming 'patterns_A' and 'patterns_B' are ready
seqs_A <- extract_seqs(patterns_A)
seqs_B <- extract_seqs(patterns_B)
cons_A <- extract_cons(patterns_A)
cons_B <- extract_cons(patterns_B)

#calculate and print overall between-group distance
overall_dist <- calc_between_group_dist(seqs_A, cons_B, seqs_B, cons_A)
print(overall_dist)
