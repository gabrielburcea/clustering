
```{r}
library(tidyverse)
library(cluster)
library(plotly)
library(fpc)
library(dendextend)
library(factoextra)
library(FactoMineR)
library(NbClust)
library(caret)
library(DMwR)
library(qgraph)
library(igraph)
```

#Read in the data and process accordingly. 




data_cluster <- read_csv("/Users/gabrielburcea/Rprojects/stats_data_whole/data_categ_nosev_comorbidity_one.csv")


data_select <- data_cluster %>%
  dplyr::select(id, age, gender, covid_tested, chills, cough, diarrhoea, fatigue, headache, loss_smell_taste, muscle_ache, 
                nasal_congestion, nausea_vomiting, shortness_breath, sore_throat, sputum, temperature, loss_appetite, chest_pain, itchy_eyes, joint_pain, 
                asthma, diabetes_type_one, diabetes_type_two, obesity, hypertension, heart_disease, lung_condition, liver_disease, kidney_disease) %>%
  dplyr::filter(covid_tested != "none") 


covid_tested_levels <- c("positive" = "showing symptoms")

data_transf <- data_select %>% 
  dplyr::mutate(covid_tested = forcats::fct_recode(covid_tested, !!!covid_tested_levels))


data_piv<- data_transf %>%
  pivot_longer(cols = 22:30, 
               names_to = "comorbidities",
               values_to = "Bolean") %>%
  dplyr::filter(Bolean != "No")

data_piv_id <- dplyr::mutate(data_piv, respondents_id = rownames(data_piv))

data_clean <- data_piv_id %>%
  dplyr::select(respondents_id, comorbidities, chills, cough, diarrhoea, fatigue, headache, loss_smell_taste, muscle_ache, 
                nasal_congestion, nausea_vomiting, shortness_breath, sore_throat, sputum, temperature, loss_appetite, chest_pain, itchy_eyes, joint_pain ) %>%
  drop_na()


#data_rec <- ifelse(data_piv_id[,3:19] == "Yes", 1,0)
#data_clean <- cbind(data_piv_id[,1:2], data_rec)

data_clean$chills <- as.factor(data_clean$chills)
data_clean$cough <- as.factor(data_clean$cough)
data_clean$diarrhoea <- as.factor(data_clean$diarrhoea)
data_clean$fatigue <- as.factor(data_clean$fatigue)
data_clean$headache <- as.factor(data_clean$headache)
data_clean$loss_smell_taste <- as.factor(data_clean$loss_smell_taste)
data_clean$muscle_ache <- as.factor(data_clean$muscle_ache)
data_clean$ nasal_congestion <- as.factor(data_clean$ nasal_congestion)
data_clean$nausea_vomiting <- as.factor(data_clean$nausea_vomiting)
data_clean$shortness_breath <- as.factor(data_clean$shortness_breath)
data_clean$sore_throat <- as.factor(data_clean$sore_throat)
data_clean$sputum <- as.factor(data_clean$sputum)
data_clean$temperature <- as.factor(data_clean$temperature)
data_clean$loss_appetite <- as.factor(data_clean$loss_appetite)
data_clean$chest_pain <- as.factor(data_clean$chest_pain)
data_clean$itchy_eyes <- as.factor(data_clean$itchy_eyes)
data_clean$joint_pain <- as.factor(data_clean$joint_pain)
data_clean <- as.data.frame(data_clean)

rownames(data_clean) <- data_clean$respondents_id

data_count <- data_clean %>% 
  pivot_longer(cols = 3:19,
               names_to = "symptoms",
               values_to = "yes_no")  %>%
  dplyr::group_by(comorbidities, symptoms, yes_no) %>%
  dplyr::summarise(Count = n()) %>%
  dplyr::mutate(Freq = Count / sum(Count)*100) %>%
  dplyr::filter(yes_no == "Yes") %>%
  dplyr::select(comorbidities, symptoms, Freq)




dt_wd <- data_count %>% 
  tidyr::pivot_wider(names_from = "symptoms", values_from = "Freq")

dt_wd <- as.data.frame(dt_wd)
dt_wd$comorbidities<- as.character(dt_wd$comorbidities)


rownames(dt_wd) <- dt_wd$comorbidities

#The hierarchical clustering gives us 4 groups. 

# Disimilarity matrix 
d <- dist(dt_wd, method  = "euclidean")

#Hierarchicla clustering using Complete Linkage
hc_complete <- hclust(d, method = "complete")

#Plot the obtained dendogram 
plot(hc_complete, cex = 0.6, hang = -31)


# However, I want to check whether this clustering is balanced. I will attempt a divisive and agglomerative method for this purpose. Additionaly, further down, I will check for the entaglement coefficient to check the quality of both dendograms. 
# 
# Divisive vs. Agglomerative clustering. 
# 
# For both, we get the same clusters where comorbidities are stored in the same groups as revealed above. 


# Compute with agnes 
hc_agnes <- agnes(dt_wd, method = "complete")

# Agglomerative coeffiecient 
hc_agnes$ac


hc_agnes_2 <- agnes(dt_wd, method = "ward")

pltree(hc_agnes_2, cex = 0.6, hang = -1, main = "Dendrogram of agnes")

#Divisive Hierarchicla Clustering 

# compute divisive hierarchical clustering 
hc_diana<- diana(dt_wd)

# Divisive coefficient; amount of clustering structure found 
hc_diana$dc


#plot dendogram 

pltree(hc_diana, cex = 0.6, hang = -1, main = "Dendogram of diana")

#Working with Dendrograms 


# Ward's method 

hc_ward_method <- hclust(d, method = "ward.D2")

# Cut tree into 4 groups 

sub_grp <- cutree(hc_ward_method, k = 4)

#Number of countries in each cluster
table(sub_grp)



plot(hc_ward_method,  cex =0.6)

rect.hclust(hc_ward_method , k = 4, border = 2:5)

res_hc <- dt_wd %>%
  dist(method = "euclidean") %>%
  hclust(method = "ward.D2")

fviz_dend(res_hc, k = 4, 
          cex = 0.5, 
          k_colors = c("#2E9FDF", "#00AFBB", "#E7B800", "#FC4E07"), 
          color_labels_by_k = TRUE, 
          rect = TRUE)



#data_piv$chills <- as.numeric(data_piv$chills )
# data_piv$cough <- as.integer(data_piv$cough )
# data_piv$diarrhoea <- as.integer(data_piv$diarrhoea)
# data_piv$fatigue <- as.integer(data_piv$fatigue)
# data_piv$headache <- as.integer(data_piv$headache)
# data_piv$loss_smell_taste <- as.integer(data_piv$loss_smell_taste)
# data_piv$muscle_ache <- as.integer(data_piv$muscle_ache)
# data_piv$nasal_congestion <- as.integer(data_piv$nasal_congestion)
# data_piv$nausea_vomiting <- as.integer(data_piv$nausea_vomiting)
# data_piv$shortness_breath <- as.integer(data_piv$shortness_breath)
# data_piv$sore_throat <- as.integer(data_piv$sore_throat)
# data_piv$sputum <- as.integer(data_piv$sputum)
# data_piv$temperature <- as.integer(data_piv$temperature)

level_key_comorbidities <-
  c("kidney disease" = "kidney_disease",
    "lung condition" = "lung_condition",
    "diabetes type one" = "diabetes_type_one",
    "diabetes type two" = "diabetes_type_two",
    "liver disease" = "liver_disease",
    "heart disease" = "heart_disease")


dt_wd <- dt_wd %>%
  dplyr::mutate(comorbidities = forcats::fct_recode(comorbidities, !!!level_key_comorbidities)) %>%
  dplyr::rename("chest pain" = "chest_pain", "itchy eyes" = "itchy_eyes",  "joint pain" = "joint_pain", "loss of appetite" = "loss_appetite", 
                "loss of smell and taste" = "loss_smell_taste", "muscle ache" = "muscle_ache", "nasal congestion" = "nasal_congestion", 
                "nausea and vomiting" = "nausea_vomiting", "shortness of breath" = "shortness_breath", "sore throat" = "sore_throat")


dt_wd  <- as.data.frame(dt_wd)
dt_wd$comorbidities <- as.character(dt_wd$comorbidities)
rownames(dt_wd) <- dt_wd$comorbidities
#data_scaled <- as.data.frame(scale(data_piv[2:14]))




# Cut agnes() tree into 4 groups
hc_a <- agnes(dt_wd, method = "ward")
cutree(as.hclust(hc_a), k = 4)

# Cut diana() tree into 4 groups
hc_d <- diana(dt_wd)

cutree(as.hclust(hc_d), k = 4)




Comparing two deprograms. Comparing hierarchical clustering with complete linkage versus Ward's method. 

# The output displays "unique" nodes, with a combination of labels/items not present in the other tree highlighted with dashed line.
# The quality of the alignment of the two trees can be measured using the function entanglement. Entanglement is a measure between 1 
# (full entanglement) 0 (no entanglement). A lower entanglement coefficient corresponds to a good alignment. 
# 
# As we compare the two dendograms, the entanglement coefficient is 0. This tells us it is a good alignment. 


# Compute distance matrix
res_dist <- dist(dt_wd, method = "euclidean")

# Compute 2 hierarchical clusterings
hc_complete <- hclust(res_dist, method = "complete")
hc_ward <- hclust(res_dist, method = "ward.D2")

# Create two dendrograms
dend_complete <- as.dendrogram (hc_complete)
dend_ward <- as.dendrogram (hc_ward)


dend_list <- dendlist(dend_complete, dend_ward)

tanglegram(dend_complete, dend_ward, 
           margin_inner = 10,
           highlight_distinct_edges = FALSE, #Turn-off dashed line
           common_subtrees_color_lines = TRUE, # Turn-off line colors
           common_subtrees_color_branches = TRUE, # Color common branches
           main = paste("entanglement =", round(entanglement(dend_list),2)))

# For the sake of interpretability and attempting to reach the aim of the research, I am designing a heatmap in order to spot whether there are differences in Covid-19 symptoms 
#in respondents with comorobidities. As observed, the heathmap gives us 4 clusters. 
# The hierarchical clustering groups: 
#  1. the respiratory comorbidities together asthma and lung disease;  
#  2. a second group related to hypertension, heart disease, diabetes type one;
#  3. with a diabetes type two separate group;
#  4. and a final group liver disease, kidney disease and obesity
#  
# The Covid-19 symptoms are manifesting more or less the same for the 3rd group  (asthma and lung condition) 
# and the fourth one (obesity, kidney disease and liver disease), however with a difference in shorthness of breath and 
# sputum where we see these symptoms more prominent in astham and lung condition. 



library(pheatmap)
pheatmap(t(dt_wd[-1]), cutree_cols = 4)


cstats.table <- function(dist, tree, k) {
  clust.assess <-
    c(
      "cluster.number",
      "n",
      "within.cluster.ss",
      "average.within",
      "average.between",
      "wb.ratio",
      "dunn2",
      "avg.silwidth"
    )
  
  clust.size <- c("cluster.size")
  
  stats.names <- c()
  
  row.clust <- c()
  
  output.stats <- matrix(ncol = k, nrow = length(clust.assess))
  
  cluster.sizes <- matrix(ncol = k, nrow = k)
  for (i in c(1:k)) {
    row.clust[i] <- paste("Cluster-", i, " size")
  }
  for (i in c(2:k)) {
    stats.names[i] <- paste("Test", i - 1)
    
    for (j in seq_along(clust.assess)) {
      output.stats[j, i] <-
        unlist(cluster.stats(d = dist, clustering = cutree(tree, k = i))[clust.assess])[j]
      
    }
    
    for (d in 1:k) {
      cluster.sizes[d, i] <-
        unlist(cluster.stats(d = dist, clustering = cutree(tree, k = i))[clust.size])[d]
      dim(cluster.sizes[d, i]) <- c(length(cluster.sizes[i]), 1)
      cluster.sizes[d, i]
      
    }
  }
  
  output.stats.df <- data.frame(output.stats)
  cluster.sizes <- data.frame(cluster.sizes)
  cluster.sizes[is.na(cluster.sizes)] <- 0
  rows.all <- c(clust.assess, row.clust)
  # rownames(output.stats.df) <- clust.assess
  output <- rbind(output.stats.df, cluster.sizes)[, -1]
  colnames(output) <- stats.names[2:k]
  rownames(output) <- rows.all
  is.num <- sapply(output, is.numeric)
  output[is.num] <- lapply(output[is.num], round, 2)
  output
}



As checked for the stability of clusters, the next step followed is looking at the measurements such as compactness of the clusters and the quality of clusters compared to one another. As observed, both clusters give us the distance in between the clusterins, a high figure, a good measure of the groups distance, which decrease with the increase of the number of test applied. With the distances between the points in the cluster is low and decreases with the number of test applied. 



stats_divisive <- cstats.table(d, hc_diana, 7)

stats_divisive



stats_agglomerative <- cstats.table(d,  hc_agnes, 7)

stats_agglomerative

# Moreover, the next step is applying the elbow method and the silhouete in order to check whether the number of clusters discovered may be challenged with the increase of the k.
# However, both elbow and silhoute methods reveal the same number of k which is 4. 


elb_div <-
  ggplot(data = data.frame(t(
    cstats.table(d, hc_diana, 7)
  )),
  aes(x = cluster.number, y = within.cluster.ss)) +
  geom_point() +
  geom_line() +
  ggtitle("Divisive clustering") +
  labs(x = "Number of clusters", y = "Within clusters sum of squares(SS)") +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme_minimal()

elb_div


elb_agglomerative <-
  ggplot(data = data.frame(t(
    cstats.table(d, hc_agnes, 7)
  )),
  aes(x = cluster.number, y = within.cluster.ss)) +
  geom_point() +
  geom_line() +
  ggtitle("Aglomerative clustering") +
  labs(x = "Number of clusters", y = "Within clusters sum of squares(SS)") +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme_minimal()

elb_agglomerative

sil_div <-
  ggplot(data = data.frame(t(
    cstats.table(d, hc_diana , 7)
  )),
  aes(x = cluster.number, y = avg.silwidth)) +
  geom_point() +
  geom_line() +
  ggtitle("Divisive clustering") +
  labs(x = "Number of clusters", y = "Average silhouette width") +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme_minimal()

sil_div

sil_agglomerative <-
  ggplot(data = data.frame(t(
    cstats.table(d, hc_agnes, 7)
  )),
  aes(x = cluster.number, y = avg.silwidth)) +
  geom_point() +
  geom_line() +
  ggtitle("Aglomerative clustering") +
  labs(x = "Number of clusters", y = "Average silhouette width") +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme_minimal()

sil_agglomerative

