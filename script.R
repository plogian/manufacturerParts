#Use the manufacturer part number to look up parts on the GSA Advantage,
#identify the lowest price and who sells it at that rate. 

library(RSelenium)

#for Docker
#docker pull selenium/standalone-firefox:2.53.0
#docker run -d -p 4445:4444 selenium/standalone-firefox:2.53.0

#setwd("~/R/ManufacturerParts")
remDr <- remoteDriver(remoteServerAddr = "192.168.99.100",port = 4445L)
remDr$open(silent = TRUE)
remDr$setImplicitWaitTimeout(10)

partlist <- list()
failed <- "failed.txt"

#list of all parts to look up in a vector
parts <- c("84693-01", "540", "CTGRM10037AFT", "5120-00-198-5401")

partsearch <- function (partnumber, i){
  remDr$navigate("https://www.gsaadvantage.gov/advantage/s/advncdSearchPrdsEnter.do")
  
  #search by "the exact phrase"
  search1 <- remDr$findElement(using="name", "advRecordNames.matchByCriteriaNamesIndexed[0]")
  exactmatch <- search1$findChildElement(using="css selector", "#TabbedPanels > div.TabbedPanelsContentGroup > div > div > form > table > tbody > tr:nth-child(1) > td > table > tbody > tr > td:nth-child(1) > select:nth-child(2) > option:nth-child(3)")
  exactmatch$clickElement()
  
  #search in "NSN or mfr part number"
  search2 <- remDr$findElement(using="name", "advRecordNames.fieldTypeCriteriaNamesIndexed[0]")
  NSN <- search2$findChildElement(using="css selector", "#TabbedPanels > div.TabbedPanelsContentGroup > div > div > form > table > tbody > tr:nth-child(1) > td > table > tbody > tr > td:nth-child(1) > select:nth-child(5) > option:nth-child(2)")
  NSN$clickElement()
  
  #sort lowest to highest price
  sortby <- remDr$findElement(using="name", "sortBy")
  lowestprice <- sortby$findChildElement(using="css selector", "#TabbedPanels > div.TabbedPanelsContentGroup > div > div > form > table > tbody > tr:nth-child(2) > td:nth-child(2) > table > tbody > tr > td:nth-child(1) > table > tbody > tr:nth-child(2) > td > select > option:nth-child(7)")
  lowestprice$clickElement()
  
  #input part number
  searchbar <- remDr$findElement(using="name", "advRecordNames.typedCriteriaInputNamesIndexed[0]")
  searchbar$sendKeysToElement(list(partnumber))
  
  #search for the part number
  searchbutton <- remDr$findElement(using="name", "searchButton")
  searchbutton$clickElement()
  Sys.sleep(3)
  
  #pull the lowest price
  firstrow <- remDr$findElement(using="css selector", "#main-alt > table > tbody > tr > td:nth-child(3) > table:nth-child(5) > tbody")
  firstrow$highlightElement()
  lowestprice <- firstrow$findChildElement(using="css selector", "#main-alt > table > tbody > tr > td:nth-child(3) > table:nth-child(5) > tbody > tr:nth-child(2) > td:nth-child(2) > table > tbody > tr:nth-child(2) > td:nth-child(1) > table > tbody > tr:nth-child(1) > td > span > strong")
  priceresult <- lowestprice$getElementText()[[1]]
  
  #pull the Contractor name
  firstrow <- remDr$findElement(using="css selector", "#main-alt > table > tbody > tr > td:nth-child(3) > table:nth-child(5) > tbody")
  firstrow$highlightElement()
  contractor <- firstrow$findChildElement(using="css selector", "#main-alt > table > tbody > tr > td:nth-child(3) > table:nth-child(5) > tbody > tr:nth-child(2) > td:nth-child(2) > table > tbody > tr:nth-child(2) > td:nth-child(3) > table > tbody > tr:nth-child(3) > td > span:nth-child(3)")
  contractorresult <- contractor$getElementText()[[1]]
  
  partlist[[i]] <<- c(partnumber, priceresult,contractorresult)
  print(partlist[[i]])
}


for (p in 1:length(parts)) {
  tryCatch({partsearch(parts[p], p)}, error=function(e){
    print("Failed")
    cat(parts[p], file=failed, append=TRUE, sep = "\n")})
}
