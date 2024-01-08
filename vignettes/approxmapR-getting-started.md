Getting Started With ApproxmapR
================
Corey Bryant, Gurudev Ilangovan
2024-01-07

Approxmap is an algorithm used for exploratory data analysis of
sequential data. When one has longitudinal data and wants to find out
the underlying patterns, one can use approxmap. `approxmapR` aims to
provide a consistent and tidy API for using the algorithm in R. This
vignette aims to demonstrate the basic workflow of approxmapR.

Installation is simple.

    install.packages("devtools")
    devtools::install_github("pinformatics/approxmapR")

\#Setting Up

To load the package use,

``` r
library(approxmapR)
```

Though it is not required, it is strongly encouraged to use the
`tidyverse` package as well. The `approxmapR` was designed with the same
paradigm and hence works cohesively with `tidyverse`. To install and
load,

    install.packages("tidyverse")

To load,

``` r
library(tidyverse)
```

    ## Warning: package 'ggplot2' was built under R version 4.3.1

    ## Warning: package 'dplyr' was built under R version 4.3.1

    ## Warning: package 'stringr' was built under R version 4.3.1

    ## Warning: package 'lubridate' was built under R version 4.3.1

    ## ── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
    ## ✔ dplyr     1.1.4     ✔ readr     2.1.4
    ## ✔ forcats   1.0.0     ✔ stringr   1.5.1
    ## ✔ ggplot2   3.4.4     ✔ tibble    3.2.1
    ## ✔ lubridate 1.9.3     ✔ tidyr     1.3.0
    ## ✔ purrr     1.0.2     
    ## ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
    ## ✖ dplyr::filter()     masks stats::filter()
    ## ✖ dplyr::group_rows() masks kableExtra::group_rows()
    ## ✖ dplyr::lag()        masks stats::lag()
    ## ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors

\#Motivation Now that everything is installed and loaded, let’s jump
into the problem and the motivation for using approxmap. Let’s say you
have a dataset that looks like this:

    ## Warning in data("demo"): data set 'demo' not found

    ## # A tibble: 51,264 × 3
    ##       id period     event      
    ##    <int> <chr>      <chr>      
    ##  1     1 1993-07-01 training   
    ##  2     2 1993-07-01 joblessness
    ##  3     3 1993-07-01 joblessness
    ##  4     4 1993-07-01 training   
    ##  5     5 1993-07-01 joblessness
    ##  6     6 1993-07-01 joblessness
    ##  7     7 1993-07-01 joblessness
    ##  8     8 1993-07-01 employment 
    ##  9     9 1993-07-01 joblessness
    ## 10    10 1993-07-01 employment 
    ## # ℹ 51,254 more rows

The base data is from the package `TraMineR` (it has been tweaked a
little for our problem) and provides the employment status of 712
individuals for each month from 1993 to 1998. Now you are interested in
answering the question, “**What are the general sequences of employment
that people go through?**”. Since there are 712 people, it is not
possible for us to decipher what the patterns are by visual inspection.
Looking for exact sequences that are present in *all* these people will
get us nowhere.

So we need to methodically formulate the solution. Let’s look at some
key terms necessary for doing that:

1.  **Item**: An item is an event that belongs to an ID. We are actually
    interested in seeing what the pattern of the items are.
2.  **Itemset**: An itemset is a collection of items within which the
    order of items doesn’t matter. A typical example of an itemset is
    *bread and butter*. Itemsets are used when the aggregation (more on
    that later) is typically such that it includes several items.
3.  **Sequence**: A sequence is an ordered collection of itemsets. This
    means that the way they are ordered matters.
4.  **Weighted Sequence**: Several sequences put together after multiple
    alignment. Multiple alignment is beyond the scope of this vignette
    but please check [this small
    example](https://en.wikipedia.org/wiki/Levenshtein_distance) to get
    an intuition.

Hence, every person (id) in our dataset represents a sequence. We
therefore have 712 sequences. Though we can extract a general pattern
from all these sequences, a better idea would be to

1.  Group similar sequences into clusters
2.  Create a weighted sequence for each cluster
3.  Extract the items that are present in a position a specified percent
    of the time.

The above steps are the crux of the approxmap algorithm.

\#Workflow

Let us go through the sequence of steps involved in analyzing the mvad
dataset using approxmap. Please note that this version of approxmap only
supports unique items within an itemset.

\##General Instructions

1.  Any time you need more information on a particular function, you
    could, as always, use `?function_name` to get detailed help.
2.  The package uses the `%>%` operator (Ctrl/Cmd + Shift + M). This
    means you can move from one function to another seamlessly.

\##1. Aggregate the data For the algorithm to create sequences, it needs
data in the form:

    ## # A tibble: 350 × 3
    ##       id period event
    ##    <int>  <int> <int>
    ##  1     1      1    63
    ##  2     1      2    20
    ##  3     1      2    22
    ##  4     1      2    23
    ##  5     1      2    50
    ##  6     1      2    66
    ##  7     1      2    96
    ##  8     1      3    16
    ##  9     1      3    50
    ## 10     1      4    51
    ## # ℹ 340 more rows

So basically we need to aggregate the dataset i.e. go from dates to
aggregations (called as period) in the package. For this we use the
`aggregate_sequences()` function. The aggregate sequences takes in a
number of parameters. `format` is used to specify the date format,
`unit` is used to specify the unit of aggregation - day, week, month and
so on, `n_units` is used to specify the number of units to aggregate. So
if unit is “week” and n_units is 4, 4 weeks becomes the unit of
aggregation. For more information please refer to the function
documentation.

The function also displays some useful statistics about the sequences.

``` r
mvad %>%
  aggregate_sequences(format = "%Y-%m-%d", unit = "month", n_units = 1)
```

    ## # A tibble: 51,264 × 5
    ## # Groups:   id [712]
    ##       id date       event       n_ndays agg_n_ndays
    ##    <int> <date>     <chr>         <dbl>       <dbl>
    ##  1     1 1993-07-01 training          0           1
    ##  2     2 1993-07-01 joblessness       0           1
    ##  3     3 1993-07-01 joblessness       0           1
    ##  4     4 1993-07-01 training          0           1
    ##  5     5 1993-07-01 joblessness       0           1
    ##  6     6 1993-07-01 joblessness       0           1
    ##  7     7 1993-07-01 joblessness       0           1
    ##  8     8 1993-07-01 employment        0           1
    ##  9     9 1993-07-01 joblessness       0           1
    ## 10    10 1993-07-01 employment        0           1
    ## # ℹ 51,254 more rows

    ## Generating summary statistics of aggregated data...

    ## The number of sequences is 712
    ## 
    ## The number of unique items is 6
    ## # A tibble: 6 × 2
    ##   item        relative_freq
    ##   <chr>               <dbl>
    ## 1 employment          1    
    ## 2 FE                  0.371
    ## 3 HE                  0.261
    ## 4 training            0.234
    ## 5 school              0.193
    ## 6 joblessness         0.192
    ## 
    ## Statistics for the number of sets per sequence:
    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##      71      71      71      71      71      71 
    ## 
    ## Statistics for the number of items in a set:
    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##       1       1       1       1       1       2 
    ## 
    ## Frequencies of items:
    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##    4315    4574    5560    8426    7706   22456

    ## # A tibble: 50,558 × 3
    ## # Groups:   id, period, event [50,558]
    ##       id period event     
    ##    <int>  <int> <chr>     
    ##  1     1      1 training  
    ##  2     1      2 training  
    ##  3     1      3 employment
    ##  4     1      4 employment
    ##  5     1      5 employment
    ##  6     1      6 employment
    ##  7     1      7 training  
    ##  8     1      8 training  
    ##  9     1      9 employment
    ## 10     1     10 employment
    ## # ℹ 50,548 more rows

`approxmapR` also allows for pre-aggregated data through the
`pre_aggregated()` function. This function ensures all the right classes
are aplied to the data before moving on to the next steps.

    pre_aggregated_df %>%
      pre_aggregated()

\##2. Cluster the data The next step involves one of the more
computationally intensive steps of the algorithm - clustering. To
cluster we simply need to pass an aggregated dataframe and the `k`
parameter, which refers to the number of nearest neighbours to consider
while clustering. In essense, lower the `k` value, higher the number of
clusters and vice-versa. Selecting the right value of k is a judgement
call that is very specific to the data.

Since it is a heavy task, we have used caching to store the results.
What caching does is compares the aggregated dataframe to the one in
memory and if it is identical, then uses the previously computed results
to cluster. For turning caching off, use the parameter `use_cache=FALSE`

``` r
mvad %>%
  aggregate_sequences(format = "%Y-%m-%d", unit = "month", n_units = 3, summary_stats=FALSE) %>%
    cluster_knn(k = 15)
```

    ## # A tibble: 51,264 × 5
    ## # Groups:   id [712]
    ##       id date       event       n_ndays agg_n_ndays
    ##    <int> <date>     <chr>         <dbl>       <dbl>
    ##  1     1 1993-07-01 training          0           1
    ##  2     2 1993-07-01 joblessness       0           1
    ##  3     3 1993-07-01 joblessness       0           1
    ##  4     4 1993-07-01 training          0           1
    ##  5     5 1993-07-01 joblessness       0           1
    ##  6     6 1993-07-01 joblessness       0           1
    ##  7     7 1993-07-01 joblessness       0           1
    ##  8     8 1993-07-01 employment        0           1
    ##  9     9 1993-07-01 joblessness       0           1
    ## 10    10 1993-07-01 employment        0           1
    ## # ℹ 51,254 more rows

    ## # A tibble: 7 × 3
    ##   cluster df_sequences           n
    ##     <int> <list>             <int>
    ## 1       1 <tibble [307 × 2]>   307
    ## 2       2 <tibble [127 × 2]>   127
    ## 3       3 <tibble [106 × 2]>   106
    ## 4       4 <tibble [79 × 2]>     79
    ## 5       5 <tibble [46 × 2]>     46
    ## 6       6 <tibble [43 × 2]>     43
    ## 7       7 <tibble [4 × 2]>       4

The output of the cluster_knn function is a dataframe with 3 columns -

1.  cluster (cluster_id)
2.  df_sequences (dataframes of id and sequences corresponding to the
    cluster)
3.  n which refers to the number of sequences in the cluster and is used
    to sort the dataframe

\##3. Extract the patterns Now that we have clustered, the next step is
to calculate a weighted sequence for each cluster. We can do this using
the `get_weighted_sequence()` function. However, the `filter_pattern()`
function automatically does this for us. So all we need to do is call
the `filter_pattern()` with the required threshold and an optional
pattern name (default is consensus).

The `threshold` parameter is used to specify the specify the proportion
of sequeneces the item must have been present in.

``` r
mvad %>%
  aggregate_sequences(format = "%Y-%m-%d", unit = "month", n_units = 1, summary_stats=FALSE) %>%
    cluster_knn(k = 15) %>%
      filter_pattern(threshold = 0.3, pattern_name = "variation")
```

    ## # A tibble: 51,264 × 5
    ## # Groups:   id [712]
    ##       id date       event       n_ndays agg_n_ndays
    ##    <int> <date>     <chr>         <dbl>       <dbl>
    ##  1     1 1993-07-01 training          0           1
    ##  2     2 1993-07-01 joblessness       0           1
    ##  3     3 1993-07-01 joblessness       0           1
    ##  4     4 1993-07-01 training          0           1
    ##  5     5 1993-07-01 joblessness       0           1
    ##  6     6 1993-07-01 joblessness       0           1
    ##  7     7 1993-07-01 joblessness       0           1
    ##  8     8 1993-07-01 employment        0           1
    ##  9     9 1993-07-01 joblessness       0           1
    ## 10    10 1993-07-01 employment        0           1
    ## # ℹ 51,254 more rows

    ## Clustering...

    ## Calculating distance matrix...

    ## Caching distance matrix...

    ## Initializing clusters...

    ## Clustering based on density...

    ## Resolving ties...

    ## ----------Done Clustering----------

    ## # A tibble: 8 × 5
    ##   cluster     n variation_pattern df_sequences       weighted_sequence
    ##     <int> <int> <W_Sq_P_L>        <list>             <W_Sqnc_L>       
    ## 1       1   303 <W_Sqnc_P [71]>   <tibble [303 × 2]> <W_Sequnc [71]>  
    ## 2       2   106 <W_Sqnc_P [71]>   <tibble [106 × 2]> <W_Sequnc [71]>  
    ## 3       3   102 <W_Sqnc_P [71]>   <tibble [102 × 2]> <W_Sequnc [71]>  
    ## 4       4    82 <W_Sqnc_P [71]>   <tibble [82 × 2]>  <W_Sequnc [71]>  
    ## 5       5    62 <W_Sqnc_P [71]>   <tibble [62 × 2]>  <W_Sequnc [73]>  
    ## 6       6    35 <W_Sqnc_P [69]>   <tibble [35 × 2]>  <W_Sequnc [73]>  
    ## 7       7    21 <W_Sqnc_P [72]>   <tibble [21 × 2]>  <W_Sequnc [72]>  
    ## 8       8     1 <W_Sqnc_P [71]>   <tibble [1 × 2]>   <W_Sequnc [71]>

We can also chain multiple `filter_pattern()` functions to keep adding
patterns.

``` r
results <-
  mvad %>%
    aggregate_sequences(format = "%Y-%m-%d", unit = "month", n_units = 3, summary_stats=FALSE) %>%
      cluster_knn(k = 15) %>%
        filter_pattern(threshold = 0.3, pattern_name = "variation") %>%
          filter_pattern(threshold = 0.4, pattern_name = "consensus")
```

    ## # A tibble: 51,264 × 5
    ## # Groups:   id [712]
    ##       id date       event       n_ndays agg_n_ndays
    ##    <int> <date>     <chr>         <dbl>       <dbl>
    ##  1     1 1993-07-01 training          0           1
    ##  2     2 1993-07-01 joblessness       0           1
    ##  3     3 1993-07-01 joblessness       0           1
    ##  4     4 1993-07-01 training          0           1
    ##  5     5 1993-07-01 joblessness       0           1
    ##  6     6 1993-07-01 joblessness       0           1
    ##  7     7 1993-07-01 joblessness       0           1
    ##  8     8 1993-07-01 employment        0           1
    ##  9     9 1993-07-01 joblessness       0           1
    ## 10    10 1993-07-01 employment        0           1
    ## # ℹ 51,254 more rows

    ## Clustering...

    ## Calculating distance matrix...

    ## Caching distance matrix...

    ## Initializing clusters...

    ## Clustering based on density...

    ## Resolving ties...

    ## ----------Done Clustering----------

\##4. Formatted output Though all the algorithmic work is done, the
output is hardly readable as the objects of interest are all present as
classes. We have not “prettified” the output by design because
concealing it would really inhibit additional explaratory possibilities.
Instead, we have a simple function that can be called for this -
`format_sequence()`

``` r
results %>% format_sequence()
```

    ## # A tibble: 7 × 6
    ##   cluster     n n_percent consensus_pattern  variation_pattern weighted_sequence
    ##     <int> <dbl> <chr>     <chr>              <chr>             <chr>            
    ## 1       1   307 43.12%    (training) (emplo… (employment, tra… <(employment:118…
    ## 2       2   127 17.84%    (school) (school)… (school) (school… <(employment:27,…
    ## 3       3   106 14.89%    (FE) (FE) (FE) (F… (FE, joblessness… <(employment:24,…
    ## 4       4    79 11.1%     (FE) (FE) (FE) (F… (FE, joblessness… <(employment:14,…
    ## 5       5    46 6.46%     (training) (train… (joblessness, tr… <(employment:4, …
    ## 6       6    43 6.04%     (FE) (FE) (FE) (F… (FE, joblessness… <(employment:9, …
    ## 7       7     4 0.56%     (FE) (FE) (employ… (FE) (FE) (emplo… <(FE:4):4 (FE:4)…

Since markdown by default limits the screen content the important output
gets truncated. So I have used another paramter called `kable` which can
be safely ignored if it doesn’t make sense. The format_sequence also has
a parameter called `compare` which when TRUE lists the patterns within a
cluster row-by-row. The r function `View()` can be chained to opened the
output dataframe in the built-in viewer but sometimes the output strings
are too large to be viewed there. So we can chain the readr function
`write_csv()` to save the output and explore the results in a text
editor or excel.

``` r
(approxmap_results <-
  mvad %>%
    aggregate_sequences(format = "%Y-%m-%d", unit = "month", n_units = 3, summary_stats=FALSE) %>%
      cluster_knn(k = 15) %>%
        filter_pattern(threshold = 0.3, pattern_name = "variation") %>%
          filter_pattern(threshold = 0.4, pattern_name = "consensus") %>%
            format_sequence(compare=TRUE))%>%
            kable()
```

    ## # A tibble: 51,264 × 5
    ## # Groups:   id [712]
    ##       id date       event       n_ndays agg_n_ndays
    ##    <int> <date>     <chr>         <dbl>       <dbl>
    ##  1     1 1993-07-01 training          0           1
    ##  2     2 1993-07-01 joblessness       0           1
    ##  3     3 1993-07-01 joblessness       0           1
    ##  4     4 1993-07-01 training          0           1
    ##  5     5 1993-07-01 joblessness       0           1
    ##  6     6 1993-07-01 joblessness       0           1
    ##  7     7 1993-07-01 joblessness       0           1
    ##  8     8 1993-07-01 employment        0           1
    ##  9     9 1993-07-01 joblessness       0           1
    ## 10    10 1993-07-01 employment        0           1
    ## # ℹ 51,254 more rows

    ## Clustering...

    ## Using cached distance matrix...

    ## Initializing clusters...

    ## Clustering based on density...

    ## Resolving ties...

    ## ----------Done Clustering----------

<table>
<thead>
<tr>
<th style="text-align:right;">
cluster
</th>
<th style="text-align:right;">
n
</th>
<th style="text-align:left;">
n_percent
</th>
<th style="text-align:left;">
pattern
</th>
<th style="text-align:left;">
sequence
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
307
</td>
<td style="text-align:left;">
43.12%
</td>
<td style="text-align:left;">
consensus
</td>
<td style="text-align:left;">
(training) (employment, training) (employment, training) (employment,
training) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment)
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
307
</td>
<td style="text-align:left;">
43.12%
</td>
<td style="text-align:left;">
variation
</td>
<td style="text-align:left;">
(employment, training) (training) (employment, training) (employment,
training) (employment, training) (employment, training) (employment,
training) (employment, training) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment)
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
307
</td>
<td style="text-align:left;">
43.12%
</td>
<td style="text-align:left;">
weighted_sequence
</td>
<td style="text-align:left;">
\<(employment:118, FE:74, joblessness:67, school:38, training:124):307
(employment:91, FE:72, joblessness:14, school:26, training:112):307
(employment:97, FE:59, joblessness:23, school:25, training:113):307
(employment:102, FE:53, joblessness:26, school:24, training:117):307
(employment:135, FE:20, joblessness:42, school:10, training:133):307
(employment:131, FE:13, joblessness:35, school:8, training:128):307
(employment:137, FE:12, joblessness:44, school:8, training:126):307
(employment:148, FE:8, joblessness:50, school:6, training:117):307
(employment:176, FE:16, joblessness:48, school:7, training:82):307
(employment:181, FE:15, joblessness:49, school:1, training:66):307
(employment:183, FE:13, joblessness:53, school:1, training:66):307
(employment:189, FE:13, joblessness:51, school:1, training:66):307
(employment:222, FE:6, joblessness:47, training:47):307 (employment:222,
FE:4, joblessness:47, training:37):307 (employment:226, FE:4, HE:1,
joblessness:52, training:32):307 (employment:231, FE:2, HE:1,
joblessness:54, training:27):307 (employment:232, FE:2, HE:1,
joblessness:60, training:23):307 (employment:231, FE:4, HE:1,
joblessness:57, training:21):307 (employment:233, FE:2, HE:1,
joblessness:59, training:19):307 (employment:238, FE:2, HE:1,
joblessness:61, training:15):307 (employment:239, FE:3, HE:1,
joblessness:64, training:12):307 (employment:239, FE:2, joblessness:65,
training:10):307 (employment:240, FE:3, joblessness:65, training:9):307
(employment:238, FE:3, joblessness:68, training:5):307 (employment:235,
FE:3, joblessness:65, training:4):307\> : 307
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
127
</td>
<td style="text-align:left;">
17.84%
</td>
<td style="text-align:left;">
consensus
</td>
<td style="text-align:left;">
(school) (school) (school) (school) (school) (school) (school) (school)
(school) (HE) (HE) (HE) (HE) (HE) (HE) (HE) (HE) (HE) (HE) (HE) (HE)
(HE) (HE) (HE) (HE)
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
127
</td>
<td style="text-align:left;">
17.84%
</td>
<td style="text-align:left;">
variation
</td>
<td style="text-align:left;">
(school) (school) (school) (school) (school) (school) (school) (school)
(school) (HE) (HE) (HE) (HE) (HE) (HE) (HE) (HE) (HE) (HE) (HE)
(employment, HE) (employment, HE) (employment, HE) (employment, HE)
(employment, HE)
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
127
</td>
<td style="text-align:left;">
17.84%
</td>
<td style="text-align:left;">
weighted_sequence
</td>
<td style="text-align:left;">
\<(employment:27, FE:3, joblessness:25, school:121, training:1):127
(employment:2, FE:3, joblessness:1, school:121, training:1):127
(employment:1, FE:3, joblessness:1, school:122, training:1):127
(employment:1, FE:3, joblessness:1, school:122, training:1):127
(employment:4, joblessness:1, school:125, training:1):127 (employment:2,
joblessness:1, school:126):127 (joblessness:1, school:126,
training:1):127 (employment:1, school:126, training:1):127
(employment:26, FE:10, HE:32, joblessness:5, school:126, training:1):127
(employment:20, FE:13, HE:66, joblessness:3, school:27, training:1):127
(employment:22, FE:13, HE:65, joblessness:3, school:24, training:2):127
(employment:23, FE:12, HE:65, joblessness:2, school:24, training:2):127
(employment:34, FE:13, HE:77, joblessness:1, school:16, training:3):127
(employment:24, FE:11, HE:92, joblessness:1, training:2):127
(employment:21, FE:11, HE:91, joblessness:3, training:3):127
(employment:23, FE:11, HE:90, joblessness:3, training:3):127
(employment:29, FE:8, HE:86, joblessness:5, training:1):127
(employment:29, FE:4, HE:90, joblessness:4, training:1):127
(employment:31, FE:4, HE:90, joblessness:3, training:1):127
(employment:33, FE:4, HE:89, joblessness:3):127 (employment:48, FE:2,
HE:77, joblessness:7, training:1):127 (employment:44, HE:76,
joblessness:6, training:3):127 (employment:46, HE:75, joblessness:5,
training:3):127 (employment:48, HE:73, joblessness:6, training:3):127
(employment:47, HE:71, joblessness:6, training:3):127\> : 127
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
106
</td>
<td style="text-align:left;">
14.89%
</td>
<td style="text-align:left;">
consensus
</td>
<td style="text-align:left;">
(FE) (FE) (FE) (FE) (FE) (FE) (FE) (FE) (employment, FE) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
106
</td>
<td style="text-align:left;">
14.89%
</td>
<td style="text-align:left;">
variation
</td>
<td style="text-align:left;">
(FE, joblessness) (FE) (FE) (FE) (FE) (FE) (FE) (FE) (employment, FE)
(employment, FE) (employment, FE) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment)
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
106
</td>
<td style="text-align:left;">
14.89%
</td>
<td style="text-align:left;">
weighted_sequence
</td>
<td style="text-align:left;">
\<(employment:24, FE:92, joblessness:37, school:20, training:2):103
(employment:1, FE:97, joblessness:1, school:7, training:1):106
(employment:1, FE:97, joblessness:1, school:7, training:1):106
(employment:4, FE:94, joblessness:4, school:7, training:1):105
(employment:4, FE:104, joblessness:8, school:1, training:1):106
(employment:2, FE:104, joblessness:1, training:1):106 (employment:8,
FE:101, joblessness:1, training:1):106 (employment:16, FE:94,
joblessness:5, training:1):106 (employment:53, FE:48, HE:2,
joblessness:13, school:1, training:6):104 (employment:57, FE:36, HE:5,
joblessness:4, training:6):106 (employment:67, FE:33, HE:4,
joblessness:9, training:6):106 (employment:70, FE:27, HE:3,
joblessness:6, training:4):106 (employment:89, FE:3, HE:1,
joblessness:14, training:5):106 (employment:92, FE:3, HE:2,
joblessness:11, training:4):106 (employment:92, FE:2, HE:1,
joblessness:9, training:5):106 (employment:95, FE:2, HE:1,
joblessness:8, training:4):106 (employment:98, FE:1, joblessness:8,
training:2):106 (employment:101, FE:1, joblessness:6):106 (FE:1,
joblessness:5):6 (employment:101, FE:1, joblessness:8):106
(employment:99, FE:1, joblessness:7):106 (employment:99,
joblessness:8):106 (employment:99, HE:1, joblessness:7):106
(employment:98, HE:1, joblessness:8):106 (employment:97, HE:1,
joblessness:8):106 (employment:97, HE:1, joblessness:8):106\> : 106
</td>
</tr>
<tr>
<td style="text-align:right;">
4
</td>
<td style="text-align:right;">
79
</td>
<td style="text-align:left;">
11.1%
</td>
<td style="text-align:left;">
consensus
</td>
<td style="text-align:left;">
(FE) (FE) (FE) (FE) (FE) (FE) (FE) (FE) (FE) (FE, HE) (FE, HE) (FE, HE)
(HE) (HE) (HE) (HE) (HE) (HE) (HE) (HE) (HE) (HE) (HE) (HE) (HE)
</td>
</tr>
<tr>
<td style="text-align:right;">
4
</td>
<td style="text-align:right;">
79
</td>
<td style="text-align:left;">
11.1%
</td>
<td style="text-align:left;">
variation
</td>
<td style="text-align:left;">
(FE, joblessness) (FE) (FE) (FE) (FE) (FE) (FE) (FE) (FE) (FE, HE) (FE,
HE) (FE, HE) (FE, HE) (HE) (HE) (HE) (HE) (HE) (HE) (HE) (employment,
HE) (employment, HE) (employment, HE) (employment, HE) (employment, HE)
</td>
</tr>
<tr>
<td style="text-align:right;">
4
</td>
<td style="text-align:right;">
79
</td>
<td style="text-align:left;">
11.1%
</td>
<td style="text-align:left;">
weighted_sequence
</td>
<td style="text-align:left;">
\<(employment:14, FE:70, joblessness:29, school:5, training:4):79
(FE:73, joblessness:1, school:2, training:4):79 (FE:73, school:2,
training:4):79 (employment:2, FE:72, school:2, training:4):79
(employment:5, FE:74, joblessness:2, training:2):79 (employment:1,
FE:75, joblessness:1, training:2):79 (employment:1, FE:75,
joblessness:2, training:3):79 (employment:4, FE:73, joblessness:2,
training:3):79 (employment:15, FE:59, HE:18, joblessness:4, school:5,
training:1):79 (employment:2, FE:32, HE:44, school:2):79 (employment:1,
FE:32, HE:44, school:2):79 (employment:1, FE:32, HE:44, school:2):79
(employment:8, FE:26, HE:48, joblessness:1, school:2):79 (employment:3,
FE:22, HE:54):79 (employment:3, FE:22, HE:54):79 (employment:5, FE:22,
HE:53):79 (employment:8, FE:19, HE:54, joblessness:3):79 (employment:6,
FE:13, HE:60):79 (employment:8, FE:13, HE:59):79 (employment:9, FE:12,
HE:58, joblessness:1):79 (employment:24, FE:5, HE:53, joblessness:1):79
(employment:29, FE:1, HE:49, joblessness:1):79 (employment:29, FE:1,
HE:48, joblessness:1):79 (employment:29, FE:1, HE:48, joblessness:2):79
(employment:30, FE:1, HE:46, joblessness:2):79\> : 79
</td>
</tr>
<tr>
<td style="text-align:right;">
5
</td>
<td style="text-align:right;">
46
</td>
<td style="text-align:left;">
6.46%
</td>
<td style="text-align:left;">
consensus
</td>
<td style="text-align:left;">
(training) (training) (training) (training) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment)
</td>
</tr>
<tr>
<td style="text-align:right;">
5
</td>
<td style="text-align:right;">
46
</td>
<td style="text-align:left;">
6.46%
</td>
<td style="text-align:left;">
variation
</td>
<td style="text-align:left;">
(joblessness, training) (training) (training) (employment, training)
(employment, training) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment)
</td>
</tr>
<tr>
<td style="text-align:right;">
5
</td>
<td style="text-align:right;">
46
</td>
<td style="text-align:left;">
6.46%
</td>
<td style="text-align:left;">
weighted_sequence
</td>
<td style="text-align:left;">
\<(employment:4, FE:3, joblessness:15, school:3, training:37):46
(employment:4, FE:2, school:3, training:39):46 (employment:7, FE:1,
joblessness:3, training:41):46 (employment:15, joblessness:2,
training:35):46 (employment:34, FE:1, joblessness:4, training:18):46
(employment:41, FE:2, joblessness:2, training:7):46 (employment:42,
FE:2, joblessness:4, training:1):46 (employment:43, FE:2,
joblessness:3):46 (employment:37, joblessness:1, training:9):46
(employment:35, joblessness:2, training:9):46 (employment:35,
joblessness:2, training:9):46 (employment:39, joblessness:1,
training:8):46 (employment:41, training:5):46 (employment:41,
training:5):46 (employment:42, training:5):46 (employment:42,
training:4):46 (employment:43, training:3):46 (employment:45,
training:2):46 (employment:45, training:1):46 (employment:46,
training:1):46 (employment:46, joblessness:1, training:1):46
(employment:44, joblessness:1, training:1):46 (employment:44,
joblessness:1, training:1):46 (employment:44, joblessness:1,
training:1):46 (employment:44, joblessness:1, training:1):46\> : 46
</td>
</tr>
<tr>
<td style="text-align:right;">
6
</td>
<td style="text-align:right;">
43
</td>
<td style="text-align:left;">
6.04%
</td>
<td style="text-align:left;">
consensus
</td>
<td style="text-align:left;">
(FE) (FE) (FE) (FE) (FE) (FE) (FE) (FE) (FE) (FE) (FE) (FE) (FE) (FE)
(FE) (FE) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
</td>
</tr>
<tr>
<td style="text-align:right;">
6
</td>
<td style="text-align:right;">
43
</td>
<td style="text-align:left;">
6.04%
</td>
<td style="text-align:left;">
variation
</td>
<td style="text-align:left;">
(FE, joblessness, school) (FE, school) (FE, school) (FE, school) (FE)
(FE) (FE) (FE) (FE) (FE) (FE) (FE) (FE) (FE) (FE) (FE) (employment, FE)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment)
</td>
</tr>
<tr>
<td style="text-align:right;">
6
</td>
<td style="text-align:right;">
43
</td>
<td style="text-align:left;">
6.04%
</td>
<td style="text-align:left;">
weighted_sequence
</td>
<td style="text-align:left;">
\<(employment:9, FE:26, joblessness:16, school:17, training:1):43
(FE:26, school:16, training:1):43 (employment:1, FE:26, school:16):43
(employment:5, FE:24, joblessness:3, school:16):41 (employment:9, FE:29,
joblessness:3, school:10, training:1):43 (employment:2, FE:29,
joblessness:1, school:10, training:1):43 (employment:2, FE:29,
joblessness:1, school:10, training:1):43 (employment:4, FE:29,
joblessness:1, school:10, training:1):43 (employment:5, FE:38,
school:10):43 (employment:1, FE:41):42 (employment:1, FE:41, HE:1):43
(employment:1, FE:41, HE:1):43 (employment:1, FE:42, HE:1,
training:1):43 (employment:1, FE:41, training:2):43 (employment:1,
FE:40, training:2):43 (employment:5, FE:39, training:2):43
(employment:26, FE:15, joblessness:4, training:2):42 (employment:30,
FE:8, HE:2, joblessness:7):42 (employment:30, FE:7, HE:1, joblessness:5,
training:1):43 (employment:29, FE:7, HE:1, joblessness:5, training:1):43
(employment:29, FE:1, joblessness:8, training:1):39 (employment:31,
FE:6, joblessness:2):38 (FE:6, joblessness:9):14 (employment:28, FE:5,
joblessness:10):43 (employment:28, FE:5, joblessness:11):43
(employment:27, FE:5, joblessness:11):43\> : 43
</td>
</tr>
<tr>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
0.56%
</td>
<td style="text-align:left;">
consensus
</td>
<td style="text-align:left;">
(FE) (FE) (employment, FE) (employment, FE) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment)
</td>
</tr>
<tr>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
0.56%
</td>
<td style="text-align:left;">
variation
</td>
<td style="text-align:left;">
(FE) (FE) (employment, FE) (employment, FE) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment) (employment)
(employment) (employment) (employment) (employment)
</td>
</tr>
<tr>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
0.56%
</td>
<td style="text-align:left;">
weighted_sequence
</td>
<td style="text-align:left;">
\<(FE:4):4 (FE:4):4 (employment:2, FE:4):4 (employment:4, FE:2):4
(employment:4):4 (employment:4):4 (employment:4):4 (employment:4):4
(employment:4):4 (employment:4):4 (employment:4):4 (employment:4):4
(employment:4):4 (employment:4):4 (employment:4):4 (employment:4):4
(employment:4):4 (employment:4):4 (employment:4):4 (employment:4):4
(employment:4):4 (employment:4):4 (employment:4):4 (employment:4):4
(employment:4):4\> : 4
</td>
</tr>
</tbody>
</table>

    approxmap_results %>% write_csv("approxmap_results.csv")

\#Using `tidyverse` to fully exploit approxmapR The output is what is
called as a tibble (a supercharged dataframe) that makes it possible to
do things like storing a list of tibbles (df_sequences) in a column. To
inspect the say the first 2 rows, we can use standard `dplyr` commands.

``` r
df_sequences <-
  mvad %>%
  aggregate_sequences(format = "%Y-%m-%d", unit = "month", n_units = 1, summary_stats=FALSE) %>%
    cluster_knn(k = 15) %>%
      top_n(2) %>%
        pull(df_sequences)
```

    ## # A tibble: 51,264 × 5
    ## # Groups:   id [712]
    ##       id date       event       n_ndays agg_n_ndays
    ##    <int> <date>     <chr>         <dbl>       <dbl>
    ##  1     1 1993-07-01 training          0           1
    ##  2     2 1993-07-01 joblessness       0           1
    ##  3     3 1993-07-01 joblessness       0           1
    ##  4     4 1993-07-01 training          0           1
    ##  5     5 1993-07-01 joblessness       0           1
    ##  6     6 1993-07-01 joblessness       0           1
    ##  7     7 1993-07-01 joblessness       0           1
    ##  8     8 1993-07-01 employment        0           1
    ##  9     9 1993-07-01 joblessness       0           1
    ## 10    10 1993-07-01 employment        0           1
    ## # ℹ 51,254 more rows

    ## Clustering...

    ## Calculating distance matrix...

    ## Caching distance matrix...

    ## Initializing clusters...

    ## Clustering based on density...

    ## Resolving ties...

    ## ----------Done Clustering----------

    ## Selecting by n

``` r
df_sequences
```

    ## [[1]]
    ## # A tibble: 303 × 2
    ##       id sequence       
    ##    <int> <Sqnc_Lst>     
    ##  1    26 <Sequence [71]>
    ##  2    68 <Sequence [71]>
    ##  3   116 <Sequence [71]>
    ##  4   120 <Sequence [71]>
    ##  5   150 <Sequence [71]>
    ##  6   169 <Sequence [71]>
    ##  7   201 <Sequence [71]>
    ##  8   202 <Sequence [71]>
    ##  9   213 <Sequence [71]>
    ## 10   237 <Sequence [71]>
    ## # ℹ 293 more rows
    ## 
    ## [[2]]
    ## # A tibble: 106 × 2
    ##       id sequence       
    ##    <int> <Sqnc_Lst>     
    ##  1   128 <Sequence [71]>
    ##  2   419 <Sequence [71]>
    ##  3   443 <Sequence [71]>
    ##  4   672 <Sequence [71]>
    ##  5   599 <Sequence [71]>
    ##  6    60 <Sequence [71]>
    ##  7   321 <Sequence [71]>
    ##  8   322 <Sequence [71]>
    ##  9   386 <Sequence [71]>
    ## 10   420 <Sequence [71]>
    ## # ℹ 96 more rows

To explore these sequences, we also have tidy print methods. The
functional programming toolkit for R, `purrr` provides an efficient
means to fully exploit such outputs.

``` r
df_sequences %>%
          map(function(df_cluster){
            df_cluster %>%
              mutate(sequence = map_chr(sequence, format_sequence))
          })
```

    ## [[1]]
    ## # A tibble: 303 × 2
    ##       id sequence                                                               
    ##    <int> <chr>                                                                  
    ##  1    26 <(employment) (employment) (employment) (employment) (employment) (emp…
    ##  2    68 <(employment) (employment) (employment) (employment) (employment) (emp…
    ##  3   116 <(employment) (employment) (employment) (employment) (employment) (emp…
    ##  4   120 <(employment) (employment) (employment) (employment) (employment) (emp…
    ##  5   150 <(employment) (employment) (employment) (employment) (employment) (emp…
    ##  6   169 <(employment) (employment) (employment) (employment) (employment) (emp…
    ##  7   201 <(employment) (employment) (employment) (employment) (employment) (emp…
    ##  8   202 <(employment) (employment) (employment) (employment) (employment) (emp…
    ##  9   213 <(employment) (employment) (employment) (employment) (employment) (emp…
    ## 10   237 <(employment) (employment) (employment) (employment) (employment) (emp…
    ## # ℹ 293 more rows
    ## 
    ## [[2]]
    ## # A tibble: 106 × 2
    ##       id sequence                                                               
    ##    <int> <chr>                                                                  
    ##  1   128 <(training) (training) (training) (training) (training) (training) (tr…
    ##  2   419 <(training) (training) (training) (training) (training) (training) (tr…
    ##  3   443 <(training) (training) (training) (training) (training) (training) (tr…
    ##  4   672 <(training) (training) (training) (training) (training) (training) (tr…
    ##  5   599 <(training) (training) (training) (training) (training) (training) (tr…
    ##  6    60 <(training) (training) (training) (training) (training) (training) (tr…
    ##  7   321 <(training) (training) (training) (training) (training) (training) (tr…
    ##  8   322 <(training) (training) (training) (training) (training) (training) (tr…
    ##  9   386 <(training) (training) (training) (training) (training) (training) (tr…
    ## 10   420 <(training) (training) (training) (training) (training) (training) (tr…
    ## # ℹ 96 more rows
