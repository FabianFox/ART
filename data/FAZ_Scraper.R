############################
# Project: ART             #
# 'Reproduktionsmedizin'   #
# FAZ                      #
############################

# Issues:

# Start Docker running selenium/standalone-firefox:
# Initialize in shell:
# docker run -d -p 4445:4444  selenium/standalone-firefox:3

# Load/install packages
# ---------------------------------------------------------------------------- #
if (!require("pacman")) install.packages("pacman")
p_load(RSelenium, tidyverse, rvest, stringr)

# Prepare RSelenium to take control of Firefox
# ---------------------------------------------------------------------------- #
# Initialize the RSelenium server running chrome
remDr <- RSelenium::rsDriver(remoteServerAddr = "localhost", port = 8887L, browser = "firefox")

# Open the client to steer the browser
rD <- remDr[["client"]]

# Prepare the FAZ-Archiv
# ---------------------------------------------------------------------------- #
# Search for: 'Reproduktionsmedizin*'
# from 01.01.1990 (earliest) to 31.12.2017
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

# Type: Interview #f_rubric_formula > option:nth-child(7) | Kommentar (#f_rubric_formula > option:nth-child(8))
typeInterview <- rD$findElement("css", "#f_rubric_formula > option:nth-child(8)")
typeInterview$clickElement()

# Search
# ---------------------------------------------------------------------------- #
searchbtn <- rD$findElement("css", "#f_c0")
searchbtn$clickElement()

# Number of pages with results
num_pages <- read_html(rD$getPageSource()[[1]]) %>%
  html_nodes("div.summary:nth-child(1) > div:nth-child(1) > span:nth-child(1)") %>%
  html_text() %>%
  str_extract(., "[:digit:]+") %>%
  strtoi()

# Round
num_pages <- ceiling(num_pages / 30)

# Show 30 per page (max)
showmore <- rD$findElement("css", "#f_maxHitnull > option:nth-child(3)")
showmore$clickElement()

# Get the current URL
url <- rD$getCurrentUrl()

link.df <- tibble(
  links = paste0("https://www.faz-biblionet.de/faz-portal/faz-archiv?q=%27Reproduktionsmedizin*%27&source=&max=30&sort=&offset=",
                 seq(0, (num_pages - 1) * 30, 30),
                 "&&_ts=1571407765142&rubric_formula=meinung.pu%2Cty.&DT_from=01.01.1990&DT_to=31.12.2017&timeFilterType=0#hitlist")
)


################################################################################
#                              WORK IN PROGRESS                                #
################################################################################

# Get the URL of the first page with all articles 
# ---------------------------------------------------------------------------- #
# All articles
allArticles <- rD$findElement("css", "#f_selectAllnull")
allArticles$clickElement()

# Show them
show <- rD$findElement("css", "#f_c9")
show$clickElement()

# Save the information
# Create a function for this purpose
# runs over: rD$getPageSource()[[1]]
faz_scraper <- function(x){
  page <- read_html(x)
  
  meta <- page %>%
    html_nodes(".docSource") %>%
    html_text()
  
  title <- page %>%
    html_nodes(".docTitle") %>%
    html_text()
  
  article <- page %>%
    html_nodes("#f .text") %>%
    html_text() %>%
    .[seq(1, length(.), 2)]
  
  df <- tibble(meta, title, article)
}

# Wrap as safe function
faz_scraper <- possibly(faz_scraper, "NA_character_")

# Test (works fine!)
test.df <- faz_scraper(rD$getPageSource()[[1]])

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
