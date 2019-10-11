############################
# Project: ART             #
# 'Reproduktionsmedizin'   #
# Der Spiegel              #
#                          #
############################

# Issues
# ---------------------------------------------------------------------------- #
# - none

# Setup
# ---------------------------------------------------------------------------- #
# Load/install packages
if(!require(pacman)) install.packages("pacman")
p_load(tidyverse, rvest, stringr, httr, lubridate)

# Search for articles in the archive of "Der Spiegel"
# Search term: "Reproduktionsmedizin*"
# Wildcard-operator is available (see: https://bit.ly/2OFpnbk)
# ---------------------------------------------------------------------------- #

# Initial page (page 1)
# Search term: "Reproduktionsmedizin*"
url <- "http://www.spiegel.de/suche/index.html?suchbegriff=%22Reproduktionsmedizin*%22&suchzeitraum=all&quellenGroup=SP"

# Number of pages results
page_num <- url %>%
  read_html() %>%
  html_nodes(":nth-child(3) .search-page-count") %>%
  html_text() %>%
  str_extract(., "[:digit:]+$") %>%
  strtoi()

# Create a dataframe with one row per article
spon.df <- tibble(
  link = paste0(url, "&pageNumber=", 1:page_num)
)

# Get the content
# ---------------------------------------------------------------------------- #
# CSS-Selectors (Nodes)
# Meta: .search-teaser div
# Title: .search-teaser .headline
# Teaser: .article-intro
# Article content: .article.intro a -> href

# Create a function that extracts the relevant information
spon_scraper <- function(x) {
  page <- read_html(x)
  
  meta <- page %>%
    html_nodes(".search-teaser div") %>%
    html_text()
  
  title <- page %>%
    html_nodes(".search-teaser .headline") %>%
    html_text()
  
  teaser <- page %>%
    html_nodes(".article-intro") %>%
    html_text()
  
  article_link <- page %>%
    html_nodes(".article-intro a") %>%
    html_attr("href")
  
  df <- tibble(meta, title, teaser, article_link)
}

# Map the function
spon.df <- map_dfr(
  spon.df$link, ~{
    Sys.sleep(sample(seq(0, 3, 0.5), 1))
    spon_scraper(.x)
  })

# Data cleaning
# ---------------------------------------------------------------------------- #
# Identify all interviews and newspaper commentaries
spon.df <- spon.df %>%
  mutate(type = case_when(str_detect(meta, "[I|i]nterview") == TRUE ~ "Interview",
                          str_detect(meta, "[K|k]ommentar") == TRUE ~ "Kommentar"),
         article_link = if_else(str_detect(article_link, "^/"), 
                                paste0("https://www.spiegel.de", article_link),
                                article_link)) %>%
         separate(meta, into = c("source", "section", "date"), 
                  sep = "[:blank:]-[:blank:]", remove = FALSE) %>%
           mutate_all(~str_trim(., "both")) %>%                     # Some articles only provide title & date
           mutate(date = ymd(parse_date_time(date, "d!.m!*.Y!")))


# Get the content of the articles
# ---------------------------------------------------------------------------- #
# Create a function
sp_scrape_art <- function(x){
  read_html(x) %>%
    html_nodes(".dig-artikel") %>%
    html_text()
}

# Scrape safely
sp_scrape_art <- possibly(sp_scrape_art, NA_character_) 

# Map over links
spon.df <- slice(spon.df, 1:10) %>%
    mutate(text = 
             map(article_link, ~{
               Sys.sleep(sample(seq(0, 3, 0.5), 1))
               sp_scrape_art(.x)
               })
           )

# UNDER CONSTRUCTION
# ---------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #
# Put the articles into the data frame with meta information
SPcorpus.df <- scrape.df %>%
  mutate(data = articles)

# Save
saveRDS(object = scrape.df, file = "./output/SPcorpus.RDS")