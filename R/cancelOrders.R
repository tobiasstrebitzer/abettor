#' Cancel unmatched/partially matched bets.
#'
#' \url{https://api.developer.betfair.com/services/webapps/docs/display/1smk3cen4v3lu3yomq5qye0ni/cancelOrders}
#'
#' \code{cancelOrders} Cancel all bets OR cancel all bets on a market OR fully
#' or partially cancel particular orders on a market. Only LIMIT orders can be
#' cancelled or partially cancelled once placed.
#'
#' @seealso \code{\link{loginBF}}, which must be executed first. Do NOT use the
#'   DELAY application key. The DELAY application key does not support price
#'   data.
#'
#' @param marketId String. The market ID of the bets to be fully or partially
#'   cancelled. While multiple bets (up to sixty, actually) can be cancelled in
#'   one call, they must all be from the same market. Required. Warning: Setting
#'   this parameter to NULL will result in the full cancellation of all
#'   unmatched bets across all markets.
#'
#' @param betIds vector (strings). The bet IDs of the bets to be cancelled- bet
#'   IDs are displayed (called Ref) on the bet information on the right hand
#'   side of market page on the betfair desktop site.
#'
#' @param sizeReductions vector (strings). If supplied, then this is a partial
#'   cancel.  The default value is NULL, which means complete cancellations are
#'   requested.
#'
#'   Note on sizeReductions values: The double within the string represents the
#'   value to be cancelled. For example, given an unmatched back of GBP100,
#'   inputting "2" as the parameter value will cancel GBP2 of the bet and leave
#'   GBP98 unmatched.
#'   
#' @param suppress Boolean. By default, this parameter is set to FALSE, meaning 
#'   that a warning is posted when the updateOrders call throws an error. Changing
#'   this parameter to TRUE will suppress this warning.      
#'
#' @param sslVerify Boolean. This argument defaults to TRUE and is optional. In
#'   some cases, where users have a self signed SSL Certificate, for example
#'   they may be behind a proxy server, Betfair will fail login with "SSL
#'   certificate problem: self signed certificate in certificate chain". If this
#'   error occurs you may set sslVerify to FALSE. This does open a small
#'   security risk of a man-in-the-middle intercepting your login credentials.
#'
#' @return Response from Betfair is stored in updateOrders variable, which
#'  is then parsed from JSON as a list. The status column recognises whether
#'  the call was successful. If the cancelOrders call throws an error, a data 
#'  frame containing error information is returned. Note that there are two types
#'  of error associated with this call. An API error is triggered, for example,
#'  when an invalid market ID is entered. Another type of error is returned if 
#'  no action is required (e.g. call to cancel a bet that has already been
#'  cancelled).
#'
#' @section Note on sizeReductions: If you want to combine partial and full
#'   cancellations, use "NULL" to signify the bet IDs that are to be fully
#'   cancelled (see examples below).
#'
#' @section Note on \code{cancelOrders}: Unlike some other functions that
#'   utilised data frame structures, this function directly converts the input
#'   to a JSON-compatible format. The JSON output is then converted back to a
#'   data frame.
#'
#' @examples
#' \dontrun{
#' To cancel all unmatched bets (across all countries), simply run cancelOrders
#' with marketId set to NULL
#'
#' cancelOrders(marketId = NULL)
#'
#' To cancel all unmatched bets on a single market, then just pass the market ID
#' in the marketId parameter:
#'
#' cancelOrders(marketId = "1.2131241")
#'
#' To fully cancel an inidividual bet on a specific market, then  include a
#' bet ID in betIds parameter:
#'
#' cancelOrders(marketId = "1.2131241",
#'             betIds = c("3431515121")
#'             )
#'
#' To partially cancel an inidividual bet on a specific market, include both
#' betIds and sizeReduction vectors:
#'
#' cancelOrders(marketId = "1.2131241",
#'             betIds = c("2451351566"),
#'             sizeReductions = c("2.0")
#'             )
#'
#' If you want a mixture of complete and partial cancellations, use "NULL"
#' to in the sizeReductions vector to determine full cancellations.
#' For example, if we wanted to combine our two previous requests:
#'
#' cancelOrders(marketId = "1.2131241",
#'             betIds = c("3431515121","2451351566"),
#'             sizeReductions = c("NULL","2.0")
#'             )
#' }
#'

cancelOrders <-
  function(marketId, betIds = NULL, sizeReductions = NULL, suppress = FALSE, sslVerify = TRUE) {
    
    options(stringsAsFactors = FALSE)
    
    if (is.null(sizeReductions))
      sizeReductions = rep("NULL", length(betIds))
    
    if (length(betIds) != length(sizeReductions))
      
      return("Bet ID and Size Reduction vectors need to have the same length")
    
    cancelOrderOps <-
      paste0(
        '[{"jsonrpc": "2.0","method": "SportsAPING/v1.0/cancelOrders","params":{"marketId": "',marketId,'","instructions": [',
        paste0(sapply(as.data.frame(t(data.frame(
          betIds, sizeReductions
        ))),function(x)
          paste0('{"betId":"',x[1],'","sizeReduction":"',x[2],'"}')),collapse = ","),']},"id": "1"}]'
      )
    
    cancelOrderOps = gsub("NULL","",cancelOrderOps)
    
    # Read Environment variables for authorisation details
    product <- Sys.getenv('product')
    token <- Sys.getenv('token')
    
    headers <- list(
      'Accept' = 'application/json', 'X-Application' = product, 'X-Authentication' = token, 'Content-Type' = 'application/json'
    )
    
    cancelOrders <-
      as.list(jsonlite::fromJSON(
        RCurl::postForm(
          Sys.getenv('betfair-betting'), .opts = list(
            postfields = cancelOrderOps, httpheader = headers, ssl.verifypeer = sslVerify
          )
        )
      ))
    
    if(is.null(cancelOrders$error)){
      if(!is.null(cancelOrders$result$errorCode) & !suppress)
        warning("Error- See output for details")
      as.data.frame(cancelOrders$result)}
    else({
      if(!suppress)
        warning("API Error- See output for details")
      as.data.frame(cancelOrders$error)})    
  }
