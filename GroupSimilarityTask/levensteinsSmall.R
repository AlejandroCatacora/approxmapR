library(stringdist)

sequences <- list(
  c("IJ", NA, "KQ", "M"),
  c("AJ", "P", "K", "LM"),
  c("I", NA, NA, "LM")
)

consensus_pattern <- c("IJ", NA, "K", "LM")

#calculate distance
calculate_element_wise_average <- function(sequences, consensus_pattern) {
  element_wise_averages <- numeric(length(consensus_pattern))
  
  for (i in seq_along(consensus_pattern)) {
    elements <- sapply(sequences, function(seq) ifelse(length(seq) >= i, seq[i], ""))
    distances <- sapply(elements, stringdist, consensus_pattern[i], method = "lv")
    element_wise_averages[i] <- mean(distances, na.rm = TRUE)
  }
  
  return(element_wise_averages)
}

element_wise_averages <- calculate_element_wise_average(sequences, consensus_pattern)

overall_average_distance <- mean(element_wise_averages, na.rm = TRUE)

print(element_wise_averages)

print(overall_average_distance)
