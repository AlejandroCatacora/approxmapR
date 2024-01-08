#Alejandro Catacora
#Dec 25,2023
#1.d: group similarity


#calculate within-group distances for A and B
#within_dist_A <- calc_within_group_dist(seqs_A, cons_A)
#within_dist_B <- calc_within_group_dist(seqs_B, cons_B)

#calculate the average within-group distance
#avg_within_dist <- (within_dist_A + within_dist_B) / 2

#calculate the overall between-group distance
#overall_between_dist <- calc_between_group_dist(seqs_A, cons_B, seqs_B, cons_A)

#calculate Group Similarity: (Between-Within) / Within
#group_similarity <- (overall_between_dist - avg_within_dist) / avg_within_dist

group_similarity <- ((overall_dist - overall_within_dist)/overall_within_dist)

#print the Group Similarity
print(glue::glue("Group Similarity: {group_similarity}"))