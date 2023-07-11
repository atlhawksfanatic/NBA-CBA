# Download the CBA from Github website

# ---- start --------------------------------------------------------------

# Parse the CBA to a raw text file:
library(pdftools)
library(tidyverse)

# Create a directory for the data
local_dir    <- "raw"
data_source <- paste0(local_dir, "/articles")
man_dir     <- paste0(local_dir, "/manual")
if (!file.exists(local_dir)) dir.create(local_dir, recursive = T)
if (!file.exists(data_source)) dir.create(data_source)
if (!file.exists(man_dir)) dir.create(man_dir)


# ---- download -----------------------------------------------------------

cba_url <- paste0("https://github.com/atlhawksfanatic/",
                  "atlhawksfanatic.github.io/raw/master/research/CBA/",
                  "2023-NBA-NBPA-Collective-Bargaining-Agreement.pdf")

cba_file <- paste(local_dir,
                  "2023-NBA-NBPA-Collective-Bargaining-Agreement.pdf",
                  sep = "/")
if (!file.exists(cba_file)) download.file(cba_url, cba_file)

# ---- parse --------------------------------------------------------------

cba <- pdf_text(cba_file)

# Remove the table of contents and the index, this is specific to 2023
cba_cut <- cba[25:676]

cba_pages_mapped <- map(cba_cut, function(x) {
  # Get rid of the top line and the problematic characters
  all_else <- str_remove(x, ".*\n+") |> 
    str_trim() |> 
    str_replace_all("“|”", '"') |> 
    str_replace_all("’", "'") |> 
    str_replace_all(fixed("$"), "\\$")
  
  exist_regex <- paste0("(ARTICLE|EXHIBIT) ([A-z]|[A-z]-[0-9])+",
                        "\n([A-Z]|\\s|[:punct:]|[0-9])*\n")
  # article_exists <- str_locate_all(x, "(ARTICLE|EXHIBIT) [A-z]+\n.*\n")
  article_exists <- str_locate_all(all_else, exist_regex)
  
  if (is_empty(article_exists[[1]])) {
    article = NA_character_
    article_name   = NA_character_
    article_roman = NA_character_
  } else {
    article = str_sub(all_else, article_exists[[1]])
    
    article_type   = word(article, 1)
    article_roman  = str_trim(word(article, 2))
    # str_remove_all(article, ".*?([a-z]|[:punct:])") |> #
    article_name   = str_remove_all(article, "\\b([A-Z]+[a-z]+|[a-z]+)\\b") |> 
      word(3, -1) |> 
      str_trim() |> 
      str_remove_all("\\n") |> 
      str_squish()
  }
  
  if (is_empty(article_exists[[1]])) {
    cba_structure <- tibble(article = article,
                            text = all_else,
                            article_name, article_roman)
    
  } else {
    cba_structure <- tibble(article = paste(article_type, article_roman),
                            text = all_else,
                            article_name, article_roman)
  }
  
  return(cba_structure)
})

# Converting the Exhibit values to numbers
exhibit_vals <- c("XXXVII PLAYER" = 37,
                  "A" = 43,
                  "B" = 44,
                  "C" = 45,
                  "D" = 46,
                  "E" = 47,
                  "F" = 48,
                  "G" = 49,
                  "H" = 50,
                  "I-1" = 51,
                  "I-2" = 51,
                  "I-3" = 51,
                  "I-4" = 51,
                  "I-5" = 51,
                  "I-6 STEROIDS" = 51,
                  "I-7" = 51,
                  "J-1" = 52,
                  "J-2" = 52)

cba_texts <- cba_pages_mapped |> 
  bind_rows() |> 
  fill(article:article_roman) |> 
  # squish the roman article and remove the weird PLAYER thing
  mutate(article_roman = str_remove(article_roman, "PLAYER") |> 
           str_squish()) |> 
  mutate(article_number =
           case_when(grepl("exhibit", article, ignore.case = T) ~
                       exhibit_vals[article_roman],
                     T ~ as.numeric(as.roman(article_roman)))) |> 
  arrange(article_number)


# As simple text files and Rmd
cba_texts |> 
  group_by(article_number) |> 
  summarise(#text = paste0(str_trim(text), collapse = ""),
    # Get rid of the leading and ending spaces to a new line
    text = paste0(str_replace_all(text, "\n\\s+|\\s+\n", "\n"),
                  collapse = ""),
    article = article[1],
    article_name = article_name[1] |> 
      str_remove_all(",") |> 
      str_replace_all("[^A-Za-z0-9]", "-")) |>
  # Also remove any situation where there are multiple spaces within a line
  mutate(text = str_replace_all(text, "[^\\S\r\n]+", " ")) |> 
  as.list() |> 
  pmap(function(article, article_name, text, article_number) {
    temp_num  <- str_pad(article_number, 2, pad = "0")
    
    temp_file <- paste0(data_source, "/", article, ".txt")
    temp_rmd  <- paste0(man_dir, "/", temp_num, "-", article_name, ".Rmd")
    print(temp_rmd)
    cat(text, file = temp_file)
    cat(text, file = temp_rmd)
  })