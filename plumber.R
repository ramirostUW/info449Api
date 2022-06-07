library(plumber)
library(dplyr)
library(mongolite)


connection_string = 'mongodb+srv://info449:info449@cluster0.tlydu.mongodb.net/?retryWrites=true&w=majority'
reviews_collection = mongo(collection="reviews", db="info449FinalProject", url=connection_string)
comments_collection = mongo(collection="comments", db="info449FinalProject", url=connection_string)
card_list_collection = mongo(collection="cardList", db="info449FinalProject", url=connection_string)

#* @apiTitle FinaLApp API
#* @apiDescription API for our 449 Final Project


#* Returns all reviews
#* @get /allReviews
function() {
  as.data.frame(reviews_collection$find())
}

#* Returns all Reviews from a specific user on the site
#* @param author user who wrote reviews
#* @get /allReviewsByUser
function(author) {
  as.data.frame(reviews_collection$find(paste0('{"author" : "', author,'" }')))
}

#* Returns all Reviews from a specific card
#* @param card card for which the reviews were written
#* @get /allReviewsByCard
function(card) {
  as.data.frame(reviews_collection$find(paste0('{"card" : "', card,'" }')))
}

#* Returns all Comments from a specific Review
#* @param card card the Review is for 
#* @param author user who wrote review
#* @get /allComentsForReview
function(card, author) {
  as.data.frame(comments_collection$find(paste0('{"reviewCard":"', card, '", 
                                                "reviewAuthor":"', author, '"}')))
}

#* Uploads review to the db
#* @param card the card that this review is for 
#* @param author user who wrote review
#* @param numStars number of stars given in this review
#* @param description what the user wrote
#* @get /uploadReview
function(card, author, numStars, description) {
  val <- data.frame(card, author, numStars = strtoi(numStars, base=0L), 
                    description, stringsAsFactors=FALSE)
  comments_collection$remove(paste0('{"reviewCard":"', card, '", 
                                                "reviewAuthor":"', author, '"}'))
  
  reviews_collection$update(paste0('{"card":"', card, '", "author":"', author, '"}'), 
                            paste0('{"$set":{"numStars":', numStars, ', "description":"', 
                                   description, '"}}'), upsert = TRUE)
  val
}


#* Uploads comment to the db
#* @param reviewCard the card that the review is for 
#* @param reviewAuthor user who wrote review
#* @param commentAuthor User who wrote comment
#* @param comment The comment the commenter made
#* @get /makeComment
function(reviewCard,reviewAuthor, commentAuthor, comment) {
  val <- data.frame(reviewCard, reviewAuthor, commentAuthor, 
                    comment, stringsAsFactors=FALSE)
  
  comments_collection$insert(val)
  val
}

#* Returns cards in descending order of rating
#* @get /cardsbyRating
function() {
  ratings <- as.data.frame(reviews_collection$find()) %>% group_by(card) %>% summarize_at(vars(numStars), mean)
  colnames(ratings) <- c('name', 'avgStars')
  returnVal<- as.data.frame(card_list_collection$find())
  ratings_summary<- ratings[order(ratings$avgStars,decreasing = TRUE), ]
  returnVal <- left_join(returnVal, ratings_summary, by = "name")
  returnVal[is.na(returnVal$avgStars),]$avgStars <- 0
  
  returnVal<- returnVal[order(returnVal$avgStars,decreasing = TRUE), ]
  
  returnVal
}

#* Returns cards in descending order of rating
#* @get /cardsbyAlphabetical
function() {
  ratings <- as.data.frame(reviews_collection$find()) %>% group_by(card) %>% summarize_at(vars(numStars), mean)
  colnames(ratings) <- c('name', 'avgStars')
  returnVal<- as.data.frame(card_list_collection$find())
  ratings_summary<- ratings[order(ratings$avgStars,decreasing = TRUE), ]
  returnVal <- left_join(returnVal, ratings_summary, by = "name")
  returnVal[is.na(returnVal$avgStars),]$avgStars <- 0
  
  returnVal<- returnVal[order(returnVal$name,decreasing = FALSE), ]
  
  returnVal
}