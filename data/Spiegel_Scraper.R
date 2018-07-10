############################
# Project: ART             #
# 'Reproduktionsmedizin'   #
# Der Spiegel              #
# 11.05.2018               #
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

# (1) Get the links to all articles on all pages
links <- vector("list", length = 9)

for(i in seq_along(links)){
  url <- paste0("http://www.spiegel.de/suche/index.html?suchbegriff=%22Reproduktionsmedizin*%22&suchzeitraum=all&quellenGroup=SP&pageNumber=", i)
  links[[i]] <- html_attr(html_nodes(read_html(url), css = ".article-intro a"), "href")
  
  Sys.sleep(sample(seq(0, 2, 0.5), 1))
}

scrape.over <- tibble(links = unlist(links), stringsAsFactors = FALSE)

# Only articles published in print issues
scrape.over <- scrape.over %>%
  mutate(print = str_detect(links, "print")) %>%
  filter(print == TRUE) %>%
  select(-print)

scrape.over <- scrape.over %>%
  mutate(links = paste0("http://www.spiegel.de", links))

# (2) Now we can access the articles via scrape.over$links
articles <- vector("character", length = nrow(scrape.over))

for(i in seq_along(scrape.over$links)){
  print(paste0("Scraping articles ", i, " of ", length(scrape.over$links)))
  
  articles[[i]] <- read_html(scrape.over$links[[i]]) %>%
    html_nodes(css = ".dig-artikel") %>%
    html_text()
  
  Sys.sleep(sample(seq(0, 3.5, 0.5), 1))
}

saveRDS(object = articles, file = "C:\\Users\\guelzauf\\Seafile\\Meine Bibliothek\\Projekte\\SpiegelArticles_100718.RDS")
