############################
# Project: ART             #
# 'Reproduktionsmedizin'   #
# Süddeutsche Zeitung      #
# 09.05.2018               #
############################

# Issues:
# - Update code (see: https://callumgwtaylor.github.io/blog/2018/02/01/using-rselenium-and-docker-to-webscrape-in-r-using-the-who-snake-database/)
# - RSelenium is not on CRAN anymore (09.05.2018)
#   + Fix: Install archived version (see below)
#   + Fix: Install from GitHub 

#library(devtools)
#install_version("binman", version = "0.1.0", repos = "https://cran.uni-muenster.de/")
#install_version("wdman", version = "0.2.2", repos = "https://cran.uni-muenster.de/")
#install_version("RSelenium", version = "1.7.1", repos = "https://cran.uni-muenster.de/")

# Start Docker running selenium/standalone-chrome:
# docker run -d -p 4445:4444 selenium/standalone-chrome

# Load packages
if (!require("pacman")) install.packages("pacman")

p_load(RSelenium, tidyverse, rvest, stringr)

# Search for articles in the archive of "SZ"
# Search term: "Reproduktionsmedizin"
# ------------------------------------------------ #

# Initialize the RSelenium server running chrome
remDr <- RSelenium::rsDriver(remoteServerAddr = "localhost", port = 4445L, browser = "firefox")

# Open the client to steer the browser
rD <- remDr[["client"]]

# Navigate to the SZ
# Search for: Reproduktionsmedizin*
# from 02.01.1992 (earliest) to 31.12.2017
# only in the printed issues of "Süddeutsche Zeitung"

# Go to the homepage
rD$navigate("https://archiv.szarchiv.de/Portal/restricted/Start.act")

# Navigate to the advanced search
adv_search <- rD$findElement(using = "css selector", ".navLinkActive")
adv_search$clickElement()

# Send search term
search_txt <- rD$findElement(using = 'css selector', '#searchTerm')
search_txt$sendKeysToElement(list("'Reproduktionsmedizin*'"))

# Configure time span and sources
fromDate <- rD$findElement(using = 'css selector', '#fromDate')
fromDate$clickElement()
fromDate$clearElement()
fromDate$sendKeysToElement(list("02.01.1992"))

toDate <- rD$findElement(using = "css", "#toDate")
toDate$clickElement()
toDate$clearElement()
toDate$sendKeysToElement(list("31.12.2017"))

# Search
search_btn <- rD$findElement(using = 'css selector', '#searchBtn')
search_btn$clickElement()

# Limit results to print issues
source <- rD$findElement(using = "css selector", "#Numeric_Box2 .menuItemSub")
source$clickElement()
print <- rD$findElement(using = 'css selector', '#NumericBox_DOCSRC_content_unselected :nth-child(1) .misubSub') # child may vary between 1 & 2
print$clickElement()

# Get the articles
# ------------------------------------------------ #
# (1) Kommentar
# Open article type window
articleType <- rD$findElement(using = "css selector", "#Numeric_Box6 .menuItemSub")
articleType$clickElement()

# Choose: Kommentar
comment <- rD$findElement(using = "css selector", "#NumericBox_ARTIKELTYPID_content_unselected > div:nth-child(5) > a:nth-child(1)")
comment$clickElement()

SZcomment <- vector(mode = "character", length = 18)
SZcommentMeta <- vector(mode = "character", length = 18)

# Meta information
SZcommentMeta <- read_html(rD$getPageSource()[[1]]) %>%
  html_nodes(".hitInfo") %>%
  html_text() %>%
  rev() # I scrape from oldest to youngest below

# The actual loop (articles)
for(i in seq(0, 18)) {
  print(paste0("Scraping article ", i, " of ", length(SZcomment)))
  num <- i + 1
  rD$navigate(paste0("https://archiv.szarchiv.de/Portal/restricted/Fulltext.act?index=", i))
  content <- read_html(rD$getPageSource()[[1]])
  
  SZcomment[[num]] <- content %>%
    html_nodes(css = "p") %>%
    html_text() %>%
    paste0(., collapse = " ")
  
  Sys.sleep(sample(seq(0, 5, 0.5), 1))
}

# ------------------------------------------------ #

# (2) Interview
# Open article type window
articleType <- rD$findElement(using = "css selector", "#Numeric_Box6 .menuItemSub")
articleType$clickElement()

# Choose: Interview
interview <- rD$findElement(using = "css selector", "#NumericBox_ARTIKELTYPID_content_unselected > div:nth-child(6)")
interview$clickElement()

SZinterview <- vector(mode = "character", length = 17)
SZinterviewMeta <- vector(mode = "character", length = 17)

# Meta information
SZinterviewMeta <- read_html(rD$getPageSource()[[1]]) %>%
  html_nodes(".hitInfo") %>%
  html_text() %>%
  rev() # I scrape from oldest to youngest below

# The actual loop
for(i in seq(0, 17)) {
  print(paste0("Scraping article ", i, " of ", length(SZinterview)))
  num <- i + 1
  rD$navigate(paste0("https://archiv.szarchiv.de/Portal/restricted/Fulltext.act?index=", i))
  content <- read_html(rD$getPageSource()[[1]])
  
  SZinterview[[num]] <- content %>%
    html_nodes(css = "p") %>%
    html_text() %>%
    paste0(., collapse = " ")
  
  Sys.sleep(sample(seq(0, 5, 0.5), 1))
}

# Put together into a data frame
SZcorpus <- tibble(
  type = c(rep("comment", length(SZcomment)), rep("interview", length(SZinterview))),
  data = c(SZcomment, SZinterview),
  meta = c(SZcommentMeta, SZinterviewMeta)
)

# saveRDS(object = SZcorpus, file = "./output/SZcorpus.RDS")