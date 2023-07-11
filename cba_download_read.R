# Download the CBA from NBPA website: http://nbpa.com/cba/

# Create a directory for the data
local_dir    <- "raw"
data_source <- paste0(local_dir, "/pages")
if (!file.exists(local_dir)) dir.create(local_dir, recursive = T)
if (!file.exists(data_source)) dir.create(data_source)

if (!file.exists(local_dir)) dir.create(local_dir)

cba_url <- paste0("http://3c90sm37lsaecdwtr32v9qof.wpengine.netdna-cdn.com/",
                  "wp-content/uploads/2016/02/",
                  "2017-NBA-NBPA-Collective-Bargaining-Agreement.pdf")

cba_file <- paste(local_dir, basename(cba_url), sep = "/")
if (!file.exists(cba_file)) download.file(cba_url, cba_file)

# Parse the CBA to a raw text file:
library(pdftools)
library(stringr)
library(tidyverse)

cba        <- pdf_text(cba_file)
# names(cba) <- seq(length(cba))
cba_toc    <- pdf_toc(cba_file)

# Write each page to a .txt file:
map2(cba, seq(length(cba)), function(cba, page){
  page      <- str_pad(page, 3, side = "left", pad = "0")
  temp_file <- paste0(data_source, "/cba_page_", page, ".txt")
  
  fileConn <- file(temp_file)
  writeLines(cba, fileConn)
  close(fileConn)
  
})

cba <- unlist(cba)

fileConn <- file(paste0(local_dir, "/cba_2017.txt"))
writeLines(cba, fileConn)
close(fileConn)