############################
# Project: ART             #
# 'Reproduktionsmedizin'   #
# Süddeutsche Zeitung      #
# 09.05.2018               #
############################

# Issues:
# - None

# Start Docker through PowerShell and initialize a selenium/standalone-firefox:
# In PowerShell:
# Command: docker run -d -p 4445:4444  selenium/standalone-firefox:3
# Find: docker ps
# Stop: docker stop 'name'

# Load packages/install packages
# ---------------------------------------------------------------------------- #
if (!require("pacman")) install.packages("pacman")
p_load(RSelenium, tidyverse, rvest, stringr)

# Search for articles in the archive of "SZ"
# Search term: "Reproduktionsmedizin"
# ---------------------------------------------------------------------------- #

# Initialize the RSelenium server running firefox
remDr <- RSelenium::rsDriver(remoteServerAddr = "localhost", port = 8887L, browser = "firefox")

# Open the client to steer the browser
rD <- remDr[["client"]]

# Navigate to the SZ
# Search for: Reproduktionsmedizin*
# from 02.01.1992 (earliest) to 31.12.2017
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
no_supp <- rD$findElement("css", "#DIZSZ")
no_supp$clickElement()

# not "Bayern"
no_bavaria <- rD$findElement("css", "#DIZBY")
no_bavaria <- rD$clickElement()

# not "Überregionale"
no_int <- rD$findElement("css", "#DIZUEREG")
no_int <- rD$clickElement()

# Search
search_btn <- rD$findElement("css", '#searchBtn')
search_btn$clickElement()

# UNDER CONSTRUCTION
# ---------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #

# Get the articles
# ------------------------------------------------ #
# (1) Kommentar
# Open article type window
articleType <- rD$findElement("css", "#Numeric_Box6 .menuItemSub")
articleType$clickElement()

# Choose: Kommentar
comment <- rD$findElement("css", "#NumericBox_ARTIKELTYPID_content_unselected > div:nth-child(5) > a:nth-child(1)")
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
articleType <- rD$findElement("css", "#Numeric_Box6 .menuItemSub")
articleType$clickElement()

# Choose: Interview
interview <- rD$findElement("css", "#NumericBox_ARTIKELTYPID_content_unselected > div:nth-child(6)")
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