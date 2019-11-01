############################
# Project: ART             #
# 'Reproduktionsmedizin'   #
# Süddeutsche Zeitung      #
############################

# Issues:
# - None

# Start Docker through PowerShell and initialize a selenium/stand alone-firefox:
# In PowerShell:
# Command: docker run -d -p 4445:4444  selenium/standalone-firefox:3
# Find: docker ps
# Stop: docker stop 'name'

# Load packages/install packages
# ---------------------------------------------------------------------------- #
if (!require("pacman")) install.packages("pacman")
p_load(RSelenium, tidyverse, rvest, stringr, rio)

# Initialize Selenium
# ---------------------------------------------------------------------------- #

# Initialize the RSelenium server running firefox
remDr <- RSelenium::rsDriver(remoteServerAddr = "localhost", port = 8887L, browser = "firefox")

# Open the client to steer the browser
rD <- remDr[["client"]]

# Navigate to the SZ & configure
# ---------------------------------------------------------------------------- #
# Search for: Reproduktionsmedizin*
# from 02.01.1990 to 31.12.2017
# only in the printed issues of "Süddeutsche Zeitung"

# Go to the homepage
rD$navigate("https://archiv.szarchiv.de/Portal/restricted/Start.act")

# Send search term
search_txt <- rD$findElement("css", "#searchTerm")
search_txt$sendKeysToElement(list("'Reproduktionsmedizin*'"))

# Configure time span and sources
fromDate <- rD$findElement("css", '#dateChip')
fromDate$clickElement()

# Start date
startDate <- rD$findElement("css", "#fromDate")
startDate$clickElement()
startDate$clearElement()
startDate$sendKeysToElement(list("01.01.1990"))

# End date
endDate <- rD$findElement("css", "#toDate")
endDate$clickElement()
endDate$clearElement()
endDate$sendKeysToElement(list("31.12.2017"))

# Limit results to print issues
source <- rD$findElement("css", "#sourcecChip > h4:nth-child(3)")
source$clickElement()

# not "Beilagen"
#no_supp <- rD$findElement("css", "#DIZSZ")
#no_supp$clickElement()

# not "Bayern"
#no_bavaria <- rD$findElement("css", "#DIZBY")
#no_bavaria <- no_bavaria$clickElement()

# not "Überregionale"
#no_int <- rD$findElement("css", "#DIZUEREG")
#no_int <- no_int$clickElement()

# Search
search_btn <- rD$findElement("css", '#searchBtn')
search_btn$clickElement()

# Save the content
# ---------------------------------------------------------------------------- #

# Number of pages
num_articles <- read_html(rD$getPageSource()[[1]]) %>%
  html_nodes(".searchResultHits") %>%
  html_text() %>%
  str_extract(., "[:digit:]+") %>%
  strtoi()
  
# Round
num_pages <- ceiling(num_articles / 40)

# Move over pages and extract meta-information
# ---------------------------------------------------------------------------- #

# Functions to extract meta-information
# (1) Extracts the meta tag
get_meta <- function(x){
  read_html(rD$getPageSource()[[1]]) %>%
    html_nodes(".hitInfo1 span") %>%
    html_text()
}

# (2) Jumps to the next page
jump_next <- function(x){
  click_next <- rD$findElement("css", ".iconGoNext")
  click_next$clickElement()
}

# Object that stores the information
# See: https://r4ds.had.co.nz/iteration.html#for-loops
meta.df <- vector("list", num_pages)

# Loop that fills the object and applies the functions (1) and (2)
for (page in seq_along(1:num_pages)) {
  print(paste0("Scraping content of page ", page, " of ", num_pages, " pages"))
  
  meta.df[[page]] <- get_meta()
  
  jump_next()
  
  Sys.sleep(sample(seq(2, 7, by = .5), 1))
}

# Save the raw data
# export(meta.df, "./output/sz_meta_raw_data.rds")
meta.df <- import("./output/sz_meta_raw_data.rds")

# Clean
meta.df <- str_split(flatten_chr(meta.df), "/") %>%
  unlist() %>%
  enframe() %>%
  filter(value != "" & value != "Bayern") %>%
  mutate(date = str_detect(value, "[:digit:]{2}.[:digit:]{2}.[:digit:]{4}")) %>%
  group_by(date) %>%
  mutate(row_id = 1:n(),
         row_id = ifelse(date == FALSE, NA, row_id)) %>%
  ungroup() %>%
  fill(row_id, .direction = "down") %>%
  group_by(row_id) %>%
  mutate(meta = paste0(value, collapse = ";")) %>%
  distinct(meta) %>%
  separate(meta, into = c("date", "source", "departmnent", "word_length", "category"), sep = ";")

# Get the articles
# ---------------------------------------------------------------------------- #
url <- "https://archiv.szarchiv.de/Portal/restricted/Fulltext.act?index="

link.df <- tibble(
  links = rev(paste0("https://archiv.szarchiv.de/Portal/restricted/Fulltext.act?index=", 
                 seq(num_articles - 1, 0)))
)

# Functions
sz_navigate <- function(x){
  rD$navigate(x) 
  rD$getPageSource()[[1]]
}

sz_scrape <- function(x){
  read_html(x) %>%
    html_nodes("#articleTextContainer") %>%
    html_text()
}

sz_navigate <- possibly(sz_navigate, NA_real_)
sz_scrape <- possibly(sz_scrape, NA_real_)

link.df <- link.df %>%
  mutate(text = 
           map(.x = links,
               ~ {Sys.sleep(sample(seq(2, 7, by = .5), 1))   # friendly scraping
                 url <- sz_navigate(.x)
                 sz_scrape(url)
                 }))

# Save
# export(link.df, "./output/sz_article_raw.rds")
link.df <- import("./output/sz_article_raw.rds")

# PARTS (yet to be integrated) 
# ---------------------------------------------------------------------------- #
# (1) Kommentar
# Open article type window
articleType <- rD$findElement("css", "#Numeric_Box6 .menuItemSub")
articleType$clickElement()

# Choose: Kommentar
comment <- rD$findElement("css", "#NumericBox_ARTIKELTYPID_content_unselected > div:nth-child(5) > a:nth-child(1)")
comment$clickElement()

SZcomment <- vector(mode = "character", length = 18)
SZcommentMeta <- vector(mode = "character", length = 18)