############################
# Project: ART             #
# 'Reproduktionsmedizin'   #
# Data cleaning            #
# 20.08.2018               #
############################

# Issues:

# Load data
# ------------------------------------------------ #
# Libraries
# Load packages
if (!require("pacman")) install.packages("pacman")

p_load(tidyverse, stringr)

# Read corpora
# (1) Get files
files <- list.files(path = "./output", pattern = "*.RDS", full.names = TRUE)

# (2) Map over files while reading
art.df <- data_frame(
  filename = str_extract(files, pattern = "[:upper:]+(?=.)")) %>%
  mutate(data = map(.x = files, ~readRDS(.)))

# Clean data
# (A) FAZ
FAZ.df <- art.df %>%
  filter(filename == "FAZ") %>%
  select(-filename) %>%
  flatten_df() %>%
  select(-title) %>%
  mutate(date = str_extract(meta, "[:digit:]{4}"),
         paper = "FAZ") %>%
  select(-meta)

# (B) Spiegel
SP.df <- art.df %>%
  filter(filename == "SP") %>%
  select(-filename) %>%
  flatten_df() %>%
  select(-c(links, teaser)) %>%
  mutate(type = case_when(type == "Kommentar" ~ "comment",
                          type == "Interview" ~ "interview"),
         date = str_extract(date, "[:digit:]{4}"),
         paper = "Spiegel")

# (C) SZ
SZ.df <- art.df %>%
  filter(filename == "SZ") %>%
  select(-filename) %>%
  flatten_df() %>%
  mutate(date = str_extract(meta, "[:digit:]{4}"),
         paper = "SZ") %>%
  select(-meta)

# Combine
art.df <- list(FAZ.df, SP.df, SZ.df) %>%
  bind_rows()