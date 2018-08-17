############################
# Project: ART             #
# 'Reproduktionsmedizin'   #
# FAZ                      #
# 16.08.2018               #
############################

# Issues:

# Start Docker running selenium/standalone-chrome:
# docker run -d -p 4445:4444 selenium/standalone-chrome

# ------------------------------------------------ #

# Load packages
if (!require("pacman")) install.packages("pacman")

p_load(RSelenium, tidyverse, rvest, stringr)

# ------------------------------------------------ #

# Initialize the RSelenium server running chrome
remDr <- RSelenium::rsDriver(remoteServerAddr = "localhost", port = 4445L, browser = "firefox")

# Open the client to steer the browser
rD <- remDr[["client"]]

# Navigate to the FAZ
# Search for: 'Reproduktionsmedizin*'
# from 02.01.1992 (earliest) to 31.12.2017
# only in the printed issues of "FAZ"

# Go to the homepage
rD$navigate("https://www.faz-biblionet.de/faz-portal")

# Identify search box
search <- rD$findElement("css", "#f_q")
search$sendKeysToElement(list("'Reproduktionsmedizin*'"))

# Open advanced search
advbutton <- rD$findElement("css", "#f_c1")
advbutton$clickElement()

# Limit search
# Date
toDate <- rD$findElement("css", "#f_DT_to")
toDate$clickElement()
toDate$clearElement()
toDate$sendKeysToElement(list("31.12.2017"))

fromDate <- rD$findElement("css", "#f_DT_from")
fromDate$clickElement()
fromDate$clearElement()
fromDate$sendKeysToElement(list("01.01.1990"))

# Dropdown: Source (only FAZ print)
source <- rD$findElement("css", "#f_source > option:nth-child(2)")
source$clickElement()

# Type: Interview
typeInterview <- rD$findElement("css", "#f_rubric_formula > option:nth-child(8)")
typeInterview$clickElement()

# Search
searchbtn <- rD$findElement("css", "#f_c0")
searchbtn$clickElement()

# All articles
allArticles <- rD$findElement("css", "#f_selectAll")
allArticles$clickElement()

# Show them
show <- rD$findElement("css", "#f_c6")
show$clickElement()

# Save the articles and meta information
interviewMeta <- read_html(rD$getPageSource()[[1]]) %>%
  html_nodes(".docSource") %>%
  html_text()

interviewArticles <- read_html(rD$getPageSource()[[1]]) %>%
  html_nodes("#f .text") %>%
  html_text() %>%
  .[seq(1, 16, 2)]

interviewTitle <- read_html(rD$getPageSource()[[1]]) %>%
  html_nodes(".docTitle") %>%
  html_text()

# ------------------------------------------------ #

# GoBack
rD$goBack()

# Type: Interview
typeComment <- rD$findElement("css", "#f_rubric_formula > option:nth-child(9)")
typeComment$clickElement()

# Search
searchbtn <- rD$findElement("css", "#f_c5")
searchbtn$clickElement()

# Show 30 per page
showmore <- rD$findElement("css", "#f_maxHits > option:nth-child(3)")
showmore$clickElement()

# All articles
allArticles <- rD$findElement("css", "#f_selectAll")
allArticles$clickElement()

# Show them
show <- rD$findElement("css", "#f_c6")
show$clickElement()

# Save the articles and meta information
# (articles only available until ~1992)
commentMeta <- read_html(rD$getPageSource()[[1]]) %>%
  html_nodes(".docSource") %>%
  html_text()

commentArticles <- read_html(rD$getPageSource()[[1]]) %>%
  html_nodes("#f .text") %>%
  html_text() %>%
  .[seq(1, 56, 2)]

commentTitle <- read_html(rD$getPageSource()[[1]]) %>%
  html_nodes(".docTitle") %>%
  html_text()

# Put everything together
FAZcorpus <- tibble(
  type = c(rep("comment", length(commentMeta)), rep("interview", length(interviewMeta))),
  data = c(commentArticles, interviewArticles),
  meta = c(commentMeta, interviewMeta),
  title = c(commentTitle, interviewTitle)
)

# Save
saveRDS(object = FAZcorpus, file = "./output/FAZcorpus.RDS")
