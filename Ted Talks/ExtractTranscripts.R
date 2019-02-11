# Webscraping 
# Extracting transcripts from Ted Talks regarding Innovation

library(data.table)
library(RCurl)
library(XML)
library(dplyr)

# inn.url <- 'https://www.ted.com/talks?page=1&sort=newest&topics%5B%5D=innovation'

# XPath author name
XPath.author <- '//*[contains(concat( " ", @class, " " ), concat( " ", "talk-link__speaker", " " ))]'

# XPath present title
XPath.title <- '//*[contains(concat( " ", @class, " " ), concat( " ", "m5", " " ))]//*[contains(concat( " ", @class, " " ), concat( " ", "ga-link", " " ))]'

# gather a list of pages to read
pages <- c(1:3)  # the most recent pages

urls <- data.table::rbindlist(lapply(pages, function(x){
        url <- paste("https://www.ted.com/talks?page=", x, 
                     "&sort=newest&topics%5B%5D=innovation", sep = "")
        data.frame(url, row.names = F)
        }), 
        fill = T)

# write a function to extract the data
webscrap <- function(urls, XPath){
        data.table::rbindlist(apply(urls, 1, function(url){
                xData <- RCurl::getURL(url)  # need the RCurl package in order to pass the URL to XML package for https server
                doc1 <- XML::htmlParse(xData)  # "HTMLInternalDocument" "HTMLInternalDocument" "XMLInternalDocument" "XMLAbstractDocument"
                extract <- getNodeSet(doc1, XPath)  # insert the XPath here
                x <- data.frame(sapply(extract, function(x) { XML::xmlValue(x) })) 
        }), fill = T) 
}

author <- webscrap(urls, XPath.author)
title <- webscrap(urls, XPath.title)

#######################################################################
####################### get the transcripts URL #######################

# typical transcript url
# inn1 <- xml2::read_html("https://www.ted.com/talks/gabriela_gonzalez_how_ligo_discovered_gravitational_waves_and_what_might_be_next/transcript")

# load stringr
library(stringr)
library(rvest)

# text cleaning up, e.g. str_to_lower, replace " " with "_"
names(author) <- "author"
names(title) <- "title"

author <- gsub(pattern = " ", replacement = "_", stringr::str_to_lower(author$author))
author <- stringi::stri_trans_general(author, "latin-ascii")  # remove diacritic marks

title <- gsub(pattern = " ", replacement = "_", stringr::str_to_lower(title$title))
title <- gsub(pattern = "\n|,|\\.|\\?|\\(|\\)", replacement = "", title)
title <- gsub(pattern = "\\'", replacement = "_", title)

# use \\p{Pd} to match em, en unicode dashes, set perl = T
title <- gsub(pattern = "\\p{Pd}", replacement = "", title, perl = T) %>%
        gsub(pattern = "__", replacement = "_")

innovation_transcripts <- data.frame(paste("https://www.ted.com/talks/", author, "_", title, "/transcript", sep = ""))

####################
## extract the p tag ##

extract_P_text <- function(urls) {
        
        data.table::rbindlist(
                
                apply(urls, 1, function(url) {
                # need RCurl to pass the URL to XML package for https server
                xData <- RCurl::getURL(url)  
                
                p_text <- xml2::read_html(xData) %>%  # "xml_document" "xml_node"    
                        rvest::html_nodes(xpath = ".//p") %>%
                        rvest::html_text(trim = T) %>%
                        paste(., collapse = "n")  # the argument collapse may be unnecessary
                
                # clean the text here #
                p_text <- gsub(pattern = "\t", "", p_text)
                p_text <- gsub(pattern = "\n", "", p_text)
                p_text <- gsub(pattern = "nSubscribe to receive email notificationswhenever new talks are published.nPlease enter an email address.nPlease enter a valid email address.nDid you mean\\?nPlease checkDailyorWeeklyand try again.nPlease check your details and try again.nPlease check your details and try again.nSorry, we\\'re currently having troubleprocessing new newsletter signups.Please try again later.nThanks\\! Please check your inboxfor a confirmation email.nIf you want to get even more from TED,like the ability to save talks to watch later,\\ sign up for a TED account now.nTED.com translations are made possible by volunteertranslators. Learn more about theOpen Translation Project.n© TED Conferences, LLC", "", p_text)
                p_text <- gsub(pattern = "\\.n", ". ", p_text)
                p_text <- gsub(pattern = "\\?n", "? ", p_text)
                p_text <- gsub(pattern = "\\)n", ") ", p_text)
                
                # put it into data.frame #
                x <- data.frame(p_text)  
        }  # the apply function ends here
        
        ), fill = T)  # the data.table::rbindlist function ends here 

}  

transcripts <- extract_P_text(innovation_transcripts)
transcripts$author <- author
transcripts$title <- title
transcripts$id <- seq(1, length(transcripts$p_text))

# still there contains some "errors" - b/c the transcripts URLs not working, e.g. sometimes the URL is different from normal structure - the title in the transcript URL is different from the presentation title and therefore the transcripts URLs cannot retrieve the transcripts

error <- grep(pattern = "reached this page in error,", x = transcripts$p_text, ignore.case = T)
transcripts$p_text[error]
error
# [1]   6  18  22  24  25  26  32  34  37  40  48  49  55  59  63  67  78  89  98 102
length(error)
# [1] 20

# remove "error"
transcripts2 <- transcripts[setdiff(x = 1:length(transcripts$p_text), error), ]

write.table(x = transcripts2, 
            file = "tedtalks_innovation_transcripts2.txt", 
            append = F, 
            row.names = F)

################################
## export to OntoGen ##
exportOntoGen <- data.frame(id = transcripts2$id,
                            body = transcripts2$p_text)

write.table(x = exportOntoGen, 
            file = "tedtalks_innovation_transcripts (for OntoGen).txt", 
            append = F, 
            sep = "\t", 
            row.names = F, 
            col.names = F)

