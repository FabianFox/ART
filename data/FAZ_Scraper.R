############################
# Project: ART             #
# 'Reproduktionsmedizin'   #
# FAZ                      #
############################

# Issues:
# - None

# Start Docker through PowerShell and initialize a selenium/standalone-firefox:
# In PowerShell:
# Command: docker run -d -p 4445:4444  selenium/standalone-firefox:3
# Find: docker ps
# Stop: docker stop 'name'

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
# Could also be done manually. But we need Selenium later. Hence, we can also
# configure the page with Selenium right from the start.
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
# source <- rD$findElement("css", "#f_source > option:nth-child(2)")
# source$clickElement()

# Type: Interview/Kommentar
# Interview: #f_rubric_formula > option:nth-child(7) | Kommentar (#f_rubric_formula > option:nth-child(8))
typeInterview <- rD$findElement("css", "#f_rubric_formula > option:nth-child(8)")
typeInterview$clickElement()

# Search
# ---------------------------------------------------------------------------- #
# Start search
searchbtn <- rD$findElement("css", "#f_c0")
searchbtn$clickElement()

# Show 30 per page
showmore <- rD$findElement("css", "#f_maxHitnull > option:nth-child(3)")
showmore$clickElement()

# Create the URLs that hold the articles
# ---------------------------------------------------------------------------- #
# Number of pages with results
num_pages <- read_html(rD$getPageSource()[[1]]) %>%
  html_nodes("div.summary:nth-child(1) > div:nth-child(1) > span:nth-child(1)") %>%
  html_text() %>%
  str_extract(., "[:digit:]+") %>%
  strtoi()

# Round
num_pages <- ceiling(num_pages / 30)

# Get the current URL
url <- rD$getCurrentUrl()[[1]]

# Create a dataframe with the respective URLs for all pages
link.df <- tibble(
  links = paste0(str_extract(url, ".+(?=[:digit:]&_ts)"),
                 seq(0, (num_pages - 1) * 30, 30),
                 str_extract(url, "(?<=offset=[:digit:]).+"))
  )

# Create functions to extract the relevant information
# ---------------------------------------------------------------------------- #
rD$navigate(link.df$links[[2]])

allArticles <- rD$findElement("css", "#f_selectAllnull")
allArticles$clickElement()

# Show them
show <- rD$findElement("css", "#f_c9")
show$clickElement()

# Navigate to articles on each page 
faz_navigate <- function(x){
  # Go to page
  rD$navigate(x)
  
  # Wait for page to load
  Sys.sleep(1.5)
  
  # Show all articles on the respective page
  allArticles <- rD$findElement("css", "#f_selectAllnull")
  allArticles$clickElement()
  
  # Show them
  show <- rD$findElement("css", "#f_c9")
  show$clickElement()
  
  Sys.sleep(1.5)
  
  rD$getCurrentUrl()[[1]]
}

# Save the information of each page
faz_scrape <- function(x){
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
faz_navigate <- possibly(faz_navigate, "NA_character_")
faz_scrape <- possibly(faz_scrape, "NA_character_")

# Map over the individual pages
faz.df <- map_dfr(
  link.df$links, ~{
    Sys.sleep(sample(seq(0, 3, 0.5), 1))
    url <- faz_navigate(.x)
    faz_scrape(url)
  })

# Save
# saveRDS(object = FAZcorpus, file = "./output/FAZcorpus.RDS")
