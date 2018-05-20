############################
# Project: ART             #
# 'Reproduktionsmedizin'   #
# Tidytext tinkering with  #
# a parliamentary debate   #
# 20.05.2018               #
############################

# Issues:
# - None

# Load/install packages
if (!require(pacman)) install.packages(pacman)
p_load(tidytext, tidyverse, forcats, scales)

# Create a tidytext 
deb19011.tidy <- deb19011.df %>%
  unnest_tokens(word, speech) # one word per line (long format) 

# Remove stopwords
# (1) Get stopwords
stopwords <- get_stopwords(language = "de")
custom_stop <- bind_rows(stopwords,
                         data_frame(word = "dass",
                                    lexicon = "custom"))

# (2) Remove
deb19011.tidy <- deb19011.tidy %>%
  anti_join(custom_stop)

# Most common words, frequency and total number of words by speaker
deb19011.freq <- deb19011.tidy %>%
  group_by(speaker) %>%
  count(word, sort = T) %>%
  mutate(proportion = n/sum(n),
         total = sum(n))

# term-frequency - inverse item frequency (tf_idf),
# see: https://www.tidytextmining.com/tfidf.html
# Look up whether stopwords should be removed
deb19011.tfidf <- deb19011.freq %>%
  bind_tf_idf(word, speaker, n) %>%
  select(-total, -proportion) %>%
  arrange(desc(tf_idf))

# Plot the tf_idf by speaker
deb19011.tfidf %>%
  arrange(desc(tf_idf)) %>%
  group_by(speaker) %>% 
  slice(1:15) %>%
  ungroup %>%
  ggplot(aes(x = fct_reorder(word, tf_idf), y = tf_idf, fill = speaker)) +
  geom_col(show.legend = FALSE) +
  labs(x = NULL, y = "tf-idf") +
  facet_wrap(~speaker, scales = "free") +
  coord_flip()



