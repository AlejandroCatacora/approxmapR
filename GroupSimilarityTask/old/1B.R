#Alejandro Catacora
#Dec 25,2023
#1.B : Calculate within Group

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


seqs_A <- extract_seqs(patterns_A)
seqs_B <- extract_seqs(patterns_B)
cons_A <- extract_cons(patterns_A)
cons_B <- extract_cons(patterns_B)

#calculate within-group distances for A and B
within_dist_A <- calc_within_group_dist(seqs_A, cons_A)
within_dist_B <- calc_within_group_dist(seqs_B, cons_B)

#calculate the overall average within-group distance
overall_within_dist <- (within_dist_A + within_dist_B) / 2

#print the overall average within-group distance
print(glue::glue("Overall within-group distance: {overall_within_dist}"))
