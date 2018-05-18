############################
# Project: ART             #
# 'Reproduktionsmedizin'   #
# Plenary debates in XML   #
# Data processing: Example #
# 17.05.2018               #
############################

# Issues:
# - None

# Load/install packages
if (!require("pacman")) install.packages("pacman")
p_load(tidyverse, xml2, XML, rvest, stringr, listviewer, selectr)

# Read data (data comes from: https://www.bundestag.de/service/opendata)
# and extract the agenda item that features ART
deb19011 <- read_xml("./protocols/19011-data.xml") %>%
  xml_find_all(xpath = "/dbtplenarprotokoll/sitzungsverlauf/tagesordnungspunkt[10]")

# Extract the actual speeches
speech <- deb19011 %>%
  xml_find_all(xpath = "rede") %>%
  html_text() %>%
  str_replace_all(pattern = "\\([^()]*\\)", replacement = "")

# Extract the speaker
speaker <- deb19011 %>%
  xml_find_all(xpath = css_to_xpath("redner:nth-child(1)")) %>%
  html_text() %>%
  unique() # error-prone

# Turn into a tibble
deb19011.df <- tibble(
  speaker = speaker,
  speech = speech
)