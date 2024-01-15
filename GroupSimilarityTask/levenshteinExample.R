library(stringdist)

#calculate distance
distance <- function(seq, cons) {
  levenshtein <- function(seq, cons) { #levenshtein distance calculation
    element_wise_averages <- numeric(length(cons))
    for (i in seq_along(cons)) {
      elements <- sapply(seq, function(s) ifelse(length(s) >= i, s[i], ""))
      distances <- sapply(elements, stringdist, cons[i], method = "lv")
      element_wise_averages[i] <- mean(distances, na.rm = TRUE)
    }
    
    return(element_wise_averages)
  }
  #average dist
  element_wise_averages <- levenshtein(seq, cons)
  #overall avg dist  
  overall_average_distance <- mean(element_wise_averages, na.rm = TRUE)
  
  return(list(element_wise_averages = element_wise_averages, overall_average_distance = overall_average_distance))
}


#dataset A Original Dataset
seqA1 <- list(
  c("A", NA, "BCX", NA,"D"),
  c("AE", "B", "BC", NA,"D"),
  c("A", NA, "B", NA, "DE"),
  c(NA, NA, "BC", NA, "DE"),
  c("AX","B", "BC", "Z", "AE"),
  c("AY", "BD", "B", NA, "EY"),
  c("B", NA, NA, "PW", "E")
)
consA1 <- c("A","B","BC",NA ,"DE")

seqA2 <- list(
  c("IJ", NA, "KQ", "M"),
  c("AJ", "P", "K", "LM"),
  c("I", NA, NA, "LM")
)
consA2 <- c("IJ", NA, "K", "LM")

#Dataset 2 Opposite Dataset
seqB1 <- list(
  c("IJ", NA,"KQ", "M"),
  c("AJ", "P", "K", "LM"),
  c("I", NA, NA, "LM"),
  c("IJ", "P", NA, NA),
  c(NA, NA, "KK", NA),
  c("J", "N", "N", "L"),
  c("J", NA, "K","LM")
)
consB1 <- c("IJ", NA, "K", "LM") 

seqB2 <- list(
  c("A", NA, "BCX", "D"),
  c("AX", "B", "BC", "AE"),
  c(NA, "B", "BC", "DE")
)
consB2 <- c("A", "B", "BC", "DE")




A1 <- distance(seqA1, consA1)
A2 <- distance(sequences, consA2)

B1 <- distance(seqB1, consB1)
B2 <- distance(seqB2, consB2)

A <- (A1$overall_average_distance + A2$overall_average_distance)/2
B <- (B1$overall_average_distance + B2$overall_average_distance)/2
withinDist <- (A+B)/2
print(withinDist)

