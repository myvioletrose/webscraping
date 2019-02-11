# rvest tutorial: scraping the web using R
#https://stat4701.github.io/edav/2015/04/02/rvest_tutorial/

if(!require(rvest)){install.packages("rvest"); require(rvest)}

imdb <- "http://www.imdb.com/title/tt1490017/"

lego_movie <- read_html(imdb)  # 'html' is deprecated. Use 'read_html' instead.

lego_movie %>%
        html_node(css = "strong span") %>%  # add the selectorgadget in Chrome in order to locate the desirable css selector
        html_text() %>%
        as.numeric()

lego_movie %>%
        html_nodes("#titleCast .itemprop span") %>%
        html_text()

lego_movie %>%
        html_nodes("table") %>%
        .[[2]] %>%
        html_table() %>%
        View()

# You can use xpath selectors instead of css: html_nodes(doc, xpath = "//table//td")).
# Extract the tag names with html_tag(), text with html_text(), a single attribute with html_attr() or all attributes with html_attrs().
# Detect and repair text encoding problems with guess_encoding() and repair_encoding().
# Navigate around a website as if you're in a browser with html_session(), jump_to(), follow_link(), back(), and forward(). Extract, modify and submit forms with html_form(), set_values() and submit_form().
# To see these functions in action, check out package demos with demo(package = "rvest").

#######################################################
# XML
# case study: scraping pages of data from imdb "Top-US-Grossing Action Feature Films"
# recommend Chrome instead of Firefox, especially for finding the XPath or CSS selector

library(data.table)
library(XML)

pages <- c(1:5)

# gather a list of pages to read
urls <- data.table::rbindlist(lapply(pages, function(x){
        url <- paste("http://www.imdb.com/search/title?genres=action&title_type=feature&sort=boxoffice_gross_us,desc&page=", x, "&ref_=adv_nxt", sep = "")
        data.frame(url, row.names = F)
}), fill = T)

# put things together
jobLocations <- data.table::rbindlist(apply(urls, 1, function(url) {
        doc1 <- XML::htmlParse(url)
        locations <- getNodeSet(doc1,'//*[contains(concat( " ", @class, " " ), concat( " ", "lister-item-header", " " ))]//a')  # get the desirable XPath
        data.frame(sapply(locations, function(x) { XML::xmlValue(x) }))
}), fill = T)

jobLocations



############################################################
############# COMPARISON BETWEEN XML VS. rvest #############
############################################################

url1 <- 'https://www.ted.com/talks?page=1&sort=newest&topics%5B%5D=innovation'

XPath.author <- '//*[contains(concat( " ", @class, " " ), concat( " ", "talk-link__speaker", " " ))]'

# method1: XML package
method1 <- RCurl::getURL(url1) %>%
        XML::htmlParse(.) %>%  # "HTMLInternalDocument" "HTMLInternalDocument" "XMLInternalDocument" "XMLAbstractDocument"
        XML::getNodeSet(., XPath.author) %>%
        sapply(., function(x) { XML::xmlValue(x) })

# method2: rvest package
method2 <- RCurl::getURL(url1) %>%
        xml2::read_html(.) %>%  # "xml_document" "xml_node"    
        rvest::html_nodes(xpath = XPath.author) %>%
        rvest::html_text(trim = T)

















