### Reading data from the web
## Webscraping: Programatically extracting data from the HTML code of websites

# Getting data off webpages - readLines()
con = url("http://scholar.google.com/citations?user=HI-I6C0AAAAJ&hl=en")  # open a connection
htmlCode = readLines(con)  # use readLines to read the data off webpages; we can set number of lines to read
close(con)  # close connection
htmlCode  # one big long string

# Or, Parsing with XML
library(XML)  # use the XML package for parsing the HTML
url <- "http://scholar.google.com/citations?user=HI-I6C0AAAAJ&hl=en"
html <- htmlTreeParse(url, useInternalNodes = T)  # set useInternalNodes = T to get the complete structure out

xpathSApply(html, "//title", xmlValue)
xpathSApply(html, "//td[@id='col-citedby']", xmlValue)

# Or, GET from the httr package (for doing the same thing as using above XML package)
library(httr)
html2 = GET(url)  # use the httr::GET() command for easily accessible website
content2 = httr::content(html2, as = "text")  # use the httr::content() to extract content from the html page, extract it as text string
parsedHtml = XML::htmlParse(content2, asText = T)  # parse out the html by using the htmlParse command
XML::xpathSApply(parsedHtml, "//title", xmlValue)

# To get more advanced http features such as POST capabilities and https access, you'll need to use the RCurl package. To do web scraping tasks with the RCurl package use the getURL() function. After the data has been acquired via getURL(), it needs to be restructured and parsed. The htmlTreeParse() function from the XML package is tailored for just this task. Using getURL() we can access a secure site so we can use the live site as an example this time.
library(RCurl)
jan09 <- getURL("https://stat.ethz.ch/pipermail/r-help/2009-January/date.html", ssl.verifypeer = FALSE)
jan09_parsed <- htmlTreeParse(jan09)


# in some complicated cases, e.g. accessing websites with passwords
pg1 = GET("http://httpbin.org/basic-auth/user/passwd")
pg1  # return error, status 401

# use the httr package to authenticate yourself
pg2 = GET("http://httpbin.org/basic-auth/user/passwd",
          authenticate("user", "passwd"))  # use the authenticate command to pass the username and password
pg2  # status 200
names(pg2)  # return different components, including handle, cookies

# use handles, see help(handle) from httr package
# This handle preserves settings and cookies across multiple requests. It is the foundation of all requests performed through the httr package, although it will mostly be hidden from the user
# So make sure that you use handles because if you use handles then you can actually access. You can sort of save the authentication across multiple accesses to a website. So if you set Google to be a handle where that Google is a particular website, then what you can do is you can tell GET to go and get that handle and you can say go get it for a specific path or you can set it a different path. So for example, if you authenticate this handle one time then the cookies will stay with that handle and you'll be authenticated. You won't have to keep authenticating over and over again as you access that website

google = handle("http://google.com")
pg1 = GET(handle = google, path = "/")
pg2 = GET(handle = google, path = "search")




