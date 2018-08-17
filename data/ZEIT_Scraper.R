############################
# Project: ART             #
# 'Reproduktionsmedizin'   #
# Die ZEIT                 #
# 17.08.2018               #
############################

# Issues:

# Start Docker running selenium/standalone-chrome:
# docker run -d -p 4445:4444 selenium/standalone-chrome

# ------------------------------------------------ #

# Load packages
if (!require("pacman")) install.packages("pacman")

p_load(tidyverse, rvest, stringr, rzeit2, diezeit, httr)

# Die Zeit API-key
apikey <- read_lines("C:/Users/guelzauf/Seafile/Meine Bibliothek/Projekte/diezeit_apikey.txt")

# Search for articles
ARTsearch <- get_content(query = "Reproduktionsmedizin", api_key = apikey, limit = 200)

# Get the articles
links <- ARTsearch$content$href %>%
  paste0(., "/komplettansicht")

# Check for multiple pages
multipage <- map(links, ~{
  Sys.sleep(sample(seq(0, 3, 0.5), 1))
  http_error(.)})

# Append URL for those with multiple pages
links.df <- tibble(
  links = ARTsearch$content$href,
  test = unlist(multipage)
) %>%
  mutate(links =
           case_when(test == FALSE ~ paste0(links, "/komplettansicht"),
                     test == TRUE ~ links))

# Get the articles with rvest

