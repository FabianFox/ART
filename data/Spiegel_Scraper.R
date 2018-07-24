############################
# Project: ART             #
# 'Reproduktionsmedizin'   #
# Der Spiegel              #
# 24.07.2018               #
############################

# Issues: Need to push to Git

# Load packages
if(!require(pacman)) install.packages("pacman")
p_load(tidyverse, rvest, stringr, httr)

# Search for articles in the archive of "Der Spiegel"
# Search term: "Reproduktionsmedizin*"
# ------------------------------------------------ #

# First page
url <- "http://www.spiegel.de/suche/index.html?suchbegriff=%22Reproduktionsmedizin*%22&suchzeitraum=all&quellenGroup=SP"

# Consecutive pages (2-8)
paste0("http://www.spiegel.de/suche/index.html?suchbegriff=%22Reproduktionsmedizin*%22&suchzeitraum=all&quellenGroup=SP&pageNumber=", "2")

# (1) Get all article teasers
type <- vector("list", length = 9)

for(i in seq_along(links)){
  url <- paste0("http://www.spiegel.de/suche/index.html?suchbegriff=%22Reproduktionsmedizin*%22&suchzeitraum=all&quellenGroup=SP&pageNumber=", i)
  type[[i]] <- html_text(html_nodes(read_html(url), css = ".search-teaser div"))
  
  Sys.sleep(sample(seq(0, 2, 0.5), 1))
}

# (2) Identify all interviews and newspaper commentaries
types.df <- tibble(teaser = unlist(type)) %>%
  mutate(type = case_when(str_detect(teaser, "Interview") == TRUE ~ "Interview",
                          str_detect(teaser, "Kommentar") == TRUE ~ "Kommentar")
         )

# (3) Get the links to all articles on all pages
links <- vector("list", length = 9)

for(i in seq_along(links)){
  url <- paste0("http://www.spiegel.de/suche/index.html?suchbegriff=%22Reproduktionsmedizin*%22&suchzeitraum=all&quellenGroup=SP&pageNumber=", i)
  links[[i]] <- html_attr(html_nodes(read_html(url), css = ".article-intro a"), "href")
  
  Sys.sleep(sample(seq(0, 2, 0.5), 1))
}

# As tibble
scrape.over <- tibble(links = unlist(links))

# (4) Merge types.df and links
scrape.df <- cbind(types.df, scrape.over)

# Only articles published in print issues
scrape.df <- scrape.df %>%
  mutate(print = str_detect(links, "print")) %>%
  filter(print == TRUE & !is.na(type)) %>%
  select(-print) %>%
  mutate(links = paste0("http://www.spiegel.de", links),
         date = str_extract(teaser, "[:digit:]{2}.[:digit:]{2}.[:digit:]{4}"))

scrape.over <- scrape.over %>%
  mutate(links = paste0("http://www.spiegel.de", links))

# (2) Now we can access the articles via scrape.over$links
articles <- vector("character", length = nrow(scrape.df))

for(i in seq_along(scrape.df$links)){
  print(paste0("Scraping articles ", i, " of ", length(scrape.df$links)))
  
  articles[[i]] <- read_html(scrape.df$links[[i]]) %>%
    html_nodes(css = ".dig-artikel") %>%
    html_text()
  
  Sys.sleep(sample(seq(0, 3.5, 0.5), 1))
}

saveRDS(object = articles, file = "C:\\Users\\guelzauf\\Seafile\\Meine Bibliothek\\Projekte\\SpiegelArticles_100718.RDS")
