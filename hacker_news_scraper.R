rm(list=ls())
gc()

#libraries
library(RSelenium)
library(rvest)
library(dplyr)
library(wdman)
library(binman)

#initialize server for page clicking
remote_driver <- rsDriver(browser = "firefox", chromever = NULL)
remDr <- remote_driver$client
remDr$open()

#function to scrape
scrape_hacker_news_with_more <- function() {
  # Navigate to the Hacker News page
  remDr$navigate("https://news.ycombinator.com/")
  
  all_ranks <- c()
  all_posts <- c()
  all_comments <- c()
  all_points <- c()
  all_submitters <- c()
  all_times <- c()
  
  # Loop to click the "more" button 3 times and scrape data
  for (i in 1:10) {
    Sys.sleep(3) # Wait for the page to load
    page_source <- remDr$getPageSource()[[1]]
    page <- read_html(page_source)
    
    # Extract the number and title of the posts
    posts <- page %>%
      html_nodes(".titleline") %>%
      html_text(trim = TRUE)
    
    # Extract the rank of the posts
    ranks <- page %>%
      html_nodes(".rank") %>%
      html_text(trim = TRUE)
    
    # Extract the number of comments
    comments <- page %>%
      html_nodes(".subline a+ a") %>%
      html_text(trim = TRUE)
    
    # Extract the points of the posts
    points <- page %>%
      html_nodes(".score") %>%
      html_text(trim = TRUE)
    
    # Extract the submitter's username
    submitters <- page %>%
      html_nodes(".hnuser") %>%
      html_text(trim = TRUE)
    
    # Extract the time since submission
    times <- page %>%
      html_nodes(".age") %>%
      html_text(trim = TRUE)
    
    # Fill missing elements with NA
    if(length(comments) < length(posts)) {
      comments <- c(comments, rep(NA, length(posts) - length(comments)))
    }
    if(length(points) < length(posts)) {
      points <- c(points, rep(NA, length(posts) - length(points)))
    }
    if(length(submitters) < length(posts)) {
      submitters <- c(submitters, rep(NA, length(posts) - length(submitters)))
    }
    if(length(times) < length(posts)) {
      times <- c(times, rep(NA, length(posts) - length(times)))
    }
    
    # Append the current page's data to the total lists
    all_posts <- c(all_posts, posts)
    all_ranks <- c(all_ranks, ranks)
    all_comments <- c(all_comments, comments)
    all_points <- c(all_points, points)
    all_submitters <- c(all_submitters, submitters)
    all_times <- c(all_times, times)
    
    # Click the "more" button to load the next set of posts
    more_button <- remDr$findElement(using = "xpath", value = "//a[@class='morelink']")
    more_button$clickElement()
  }
  
  # Combine the data into a data frame
  data <- data.frame(
    Rank = all_ranks,
    Title = all_posts,
    Comments = all_comments,
    Points = all_points,
    Submitter = all_submitters,
    Time = all_times
  )
  
  return(data)
}

# Call the function and print the results
hacker_news_posts <- scrape_hacker_news_with_more()
print(hacker_news_posts)

# Close the RSelenium client and server
remDr$close()
remote_driver$server$stop()

write.csv(hacker_news_posts, "~/Desktop/hacker_news_posts1.csv")
