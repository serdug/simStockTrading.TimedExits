# Copyright (c) 2020 Sergey Dugaev
# Licensed under the MIT license.
# See the LICENSE file in the project root for more information.
#
# Functions to be copied into local environments specific to each set of input 
# signals and/or prices.

prices <- function() {
  # Initializes a list for arguments holding calculation results
  # Requires:
  #   ast - a list for arguments to hold calculation results
  #   sig - a data frame containing: 
  #         Date (character) - date, time stamp, period or bar ID
  #         C (numeric) - close price
  #         T (numeric) - trade price
  
  # ast <<- list()
  
  ast$Date    <<- sig$Date
  ast$ClosePx <<- sig$C
  ast$TradePx <<- sig$T
}

removing <- function(x, keep = 5) {
  # Allows to correctly calculate the quantitity of stocks remaining in 
  # position by deriving close signals from opening signals (additions) 
  # and the duration of holding period.
  #
  # Args:
  #   x:    a numeric vector of additions
  #   keep: an integer indicating the increment of the index to
  #         the next trade; the default is 5, as if the position was closed 
  #         on the 5th trade day after opening
  #
  # Returns:
  #   a vector of removals (num): It has 1 column.
  #   
  # Requires:
  #   Package 'magrittr' for a forward-pipe operator (%>%)
  require("magrittr")
  
  # sdiff <- -x[1:(length(x) - keep)]
  # rem <- c(rep(0, keep), sdiff[1:(length(sdiff))])
  # return(rem)
  
  -x[1:(length(x) - keep)] %>% shift(., keep)
}

positions <- function() {
  positionsAdd()
  positionsRem()
  positionsEnd()
}

positionsAdd <- function() {
  # Positions, additions
  ast$S$Pos$I <<- -abs(sig$Dn)
  ast$L$Pos$I <<- -abs(sig$Up)
}

positionsRem <- function() {
  # Positions, removals
  ast$S$Pos$O <<- removing(ast$S$Pos$I, keep = HoldPer)
  ast$L$Pos$O <<- removing(ast$L$Pos$I, keep = HoldPer)
}

positionsEnd <- function() {
  # Positions, ending balance
  ast$S$Pos$E <<- cumsum(ast$S$Pos$I + ast$S$Pos$O)
  ast$L$Pos$E <<- cumsum(ast$L$Pos$I + ast$L$Pos$O)
}

quantity <- function() {
  stocksAdd()
  stocksRem()
  stocksVar()
  stocksEnd()
}

stocksAdd <- function() {
  # Stocks, additions
  ast$S$Qty$I <<- -abs(sig$Dn) * LimPP / ast$TradePx
  ast$L$Qty$I <<- +abs(sig$Up) * LimPP / ast$TradePx
}

stocksRem <- function() {
  # Stocks, removals
  ast$S$Qty$O <<- removing(ast$S$Qty$I, keep = HoldPer)
  ast$L$Qty$O <<- removing(ast$L$Qty$I, keep = HoldPer)
}

stocksVar <- function() {
  # Stocks, change of quantity (variance). Useful for calculating commissions.
  # Note: The sum of broker's commissions depend on the difference between
  # the quantities of added and removed stocks
  ast$S$VarQty <<- ast$S$Qty$I + ast$S$Qty$O
  ast$L$VarQty <<- ast$L$Qty$I + ast$L$Qty$O
}

stocksEnd <- function() {
  # Stocks, ending balance
  ast$S$Qty$E <<- cumsum(ast$S$VarQty)
  ast$L$Qty$E <<- cumsum(ast$L$VarQty)
}

commissions <- function() {
  # Broker's commissions
  ast$S$Comm <<- abs(ast$S$VarQty) * Fee
  ast$L$Comm <<- abs(ast$L$VarQty) * Fee
}

proceeds <- function() {
  proceedsAdd()
  proceedsRem()
}

proceedsAdd <- function() {
  # PROCEEDS (CASH FLOW), additions (Gross)
  ast$S$CF$I <<- -ast$S$Qty$I * ast$TradePx
  ast$L$CF$I <<- -ast$L$Qty$I * ast$TradePx
}

proceedsRem <- function() {
  # PROCEEDS (CASH FLOW), removals (Gross)
  ast$S$CF$O <<- -ast$S$Qty$O * ast$TradePx
  ast$L$CF$O <<- -ast$L$Qty$O * ast$TradePx
}

basis <- function() {
  basisAdd()
  basisRem()
  basisEnd()
}

basisAdd <- function() {
  # BASIS, additions
  ast$S$Basis$I <<- -ast$S$CF$I
  ast$L$Basis$I <<- -ast$L$CF$I
}

basisRem <- function() {
  # BASIS, removals
  ast$S$Basis$O <<- removing(ast$S$Basis$I, keep = HoldPer)
  ast$L$Basis$O <<- removing(ast$L$Basis$I, keep = HoldPer)
}

basisEnd <- function() {
  # BASIS, ending balance
  ast$S$Basis$E <<- cumsum(ast$S$Basis$I + ast$S$Basis$O)
  ast$L$Basis$E <<- cumsum(ast$L$Basis$I + ast$L$Basis$O)
}

totals <- function() {
  values()
  
  unrealized()
  unrealizedVar()
  
  realized()
  
  netReturns()
  cumReturns()
}

values <- function() {
  # Value, ending (at the Close price)
  ast$S$ValueEoD <<- ast$S$Qty$E * ast$ClosePx
  ast$L$ValueEoD <<- ast$L$Qty$E * ast$ClosePx
}

unrealized <- function() {
  # Unrealized results
  ast$S$Unr <<- ast$S$ValueEoD - ast$S$Basis$E
  ast$L$Unr <<- ast$L$ValueEoD - ast$L$Basis$E
}

unrealizedVar <- function() {
  # Change in unrealized (variance)
  ast$S$VarUnr <<- c(0, diff(ast$S$Unr))
  ast$L$VarUnr <<- c(0, diff(ast$L$Unr))
}

realized <- function() {
  # Realized results
  ast$S$Rzd <<- ast$S$CF$O + ast$S$Basis$O
  ast$L$Rzd <<- ast$L$CF$O + ast$L$Basis$O
}

netReturns <- function() {
  # Ending returns (daily)
  ast$S$Return <<- ast$S$Rzd + ast$S$VarUnr - ast$S$Comm
  ast$L$Return <<- ast$L$Rzd + ast$L$VarUnr - ast$L$Comm
}

cumReturns <- function() {
  # Cumulative (running) returns
  ast$S$CumReturn <<- cumsum(ast$S$Return)
  ast$L$CumReturn <<- cumsum(ast$L$Return)
}

assets <- function() {
  # Net Asset Values
  ast$NAV <<- Cash + ast$S$CumReturn + ast$L$CumReturn
}

drawdowns <- function() {
  ast$Drawdown <<- ifelse((ast$NAV - cummax(ast$NAV)) < 0,
                           (ast$NAV - cummax(ast$NAV)), 0) / Cash
  # Maximum Drawdown
  ast$MDD <<- cummin(ast$Drawdown)
}

shift <- function(x, n) {
  # Returns a numeric vector of the same length as x with 0 propagated n times 
  # at the beginning and values shifted forward by n positions.
  c(rep(0, n), x[1:(length(x))])
}
