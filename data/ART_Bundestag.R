############################
# Project: ART             #
# 'Reproduktionsmedizin'   #
# Bundestag debates        #
# 11.05.2018               #
############################

# Issues:
# - None

# Start Docker running selenium/standalone-chrome:
# docker run -d -p 4445:4444 selenium/standalone-chrome

# Load packages
if (!require("pacman")) install.packages("pacman")
p_load(RSelenium, tidyverse, rvest, stringr)

# Use RSelenium do download Bundestag debates on 'Reproduktionsmedizin'
# Initialize the RSelenium server running chrome
remDr <- RSelenium::rsDriver(remoteServerAddr = "localhost", port = 4445L, browser = "chrome")

# Open the client to steer the browser
rD <- remDr[["client"]]

# Navigate to the search page
rD$navigate(url = "http://dipbt.bundestag.de/dip21.web/bt")
rD$navigate("http://dipbt.bundestag.de/dip21.web/searchDocuments.do")

# Choose search settings
# Only Bundestag documents
set_bund <- rD$findElement(using = "css", "#Bundestag")
set_bund$clickElement() 

# Only protocols of the debates
set_prtcl <- rD$findElement("css", "#Plenarprotokoll")
set_prtcl$clickElement()

# All legislative periods (dropdown menu)
leg_cycle <- rD$findElement("css", "#wahlperiode")
leg_cycle$clickElement()

# Choose "all"
option_all <- rD$findElement("css", "#wahlperiode > option:nth-child(1)")
option_all$clickElement()

# Enter "Reproduktionsmedizin" into the search field
src_field <- rD$findElement("css", "#suchwort")
src_field$clickElement()
src_field$sendKeysToElement(list("Reproduktionsmedizin"))

# Click the search button
src_btn <- rD$findElement("css", "#btnSuche")
src_btn$clickElement()

# Identify the debates on "Reproduktionsmedizin" and download them
# (1) Get ID of the debate, date and the URL of the protocol
page_source <- rD$getPageSource()[[1]]
debate_id <- read_html(page_source) %>%
  html_nodes(css = "td:nth-child(2) a") %>%
  html_text()

date <- read_html(page_source) %>%
  html_nodes(css = "td:nth-child(5)") %>%
  html_text()

pdf_url <- read_html(page_source) %>%
  html_nodes(css = "td:nth-child(2) a") %>%
  html_attr(name = "href")

# Table with the above information and pdf-URL
art_df <- tibble(
  id = debate_id,
  date = date,
  url = pdf_url,
  id_paste = str_replace_all(id, "/", "")) %>%
  mutate(dest = paste0("./data/BundestagProtocol/", id_paste, ".pdf"))

# Download the protocols
map2(.x = art_df$url, .y = art_df$dest, .f = ~download.file(url = .x, destfile = .y, mode = "wb"))
