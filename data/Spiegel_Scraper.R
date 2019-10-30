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
p_load(tidyverse, rvest, stringr, httr, lubridate, tif)

# Search for articles in the archive of "Der Spiegel"
# Search term: "Reproduktionsmedizin*"
# Wildcard-operator is available (see: https://bit.ly/2OFpnbk)
# ---------------------------------------------------------------------------- #

# Initial page (page 1)
# Search term: "Reproduktionsmedizin*"
url <- "http://www.spiegel.de/suche/index.html?suchbegriff=%22Reproduktionsmedizin*%22&suchzeitraum=all&quellenGroup=SPOX&quellenGroup=SP"

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
# Article content (href-attribute): .article.intro a

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

# Wrap as safe-function
spon_scraper <- possibly(spon_scraper, "NA_real_")

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

# Save the warning message
last.message <- names(warnings())

# Extract rows affected by warning
warning.rows <- strtoi(str_extract_all(last.message, "[:digit:]+(?=[,|\\]])")[[1]])

# Warning affects articles without "section"-info. Section (features the date) 
# needs to be pushed one column to the right.
spon.df[warning.rows, "date"] <- ymd(parse_date_time(spon.df[warning.rows, "section"][[1]], "%d.%m.%Y"))
spon.df[warning.rows, "section"] <- NA_character_

# Filter: Articles published between 01.01.1990 - 31.12.2018
spon.df <- spon.df %>%
  filter(between(date, ymd("1990-01-01"), ymd("2018-12-31")))

# Save dataset
#saveRDS(spon.df, "./output/spon_links.rds")


# Get the content of the articles
# ---------------------------------------------------------------------------- #
# Read dataset with links
spon.df <- readRDS("./output/spon_links.rds")

# Create a function
sp_scrape_content <- function(x, y){
  read_html(x) %>%
    html_nodes(y) %>%
    html_text()
}

# Scrape safely
sp_scrape_content <- possibly(sp_scrape_content, NA_character_) 

# Condition for differing nodes
spon.df <- spon.df %>%
  mutate(condition = if_else(source == "SPIEGEL ONLINE", 
                             ".article-section",
                             ".dig-artikel"))

# Map over links
spon.df <- spon.df %>%                 
    mutate(
      text = 
             map2(.x = article_link, .y = condition,
                  ~{Sys.sleep(sample(seq(0, 5, 0.5), 1))
                    sp_scrape_content(x = .x, y = .y)
                    }))

# UNDER CONSTRUCTION
# ---------------------------------------------------------------------------- #
# 1 Check tif requirements
# 2 Put the articles into the data frame with meta information
SPcorpus.df <- scrape.df

# Save
saveRDS(object = scrape.df, file = "./output/SPcorpus.RDS")