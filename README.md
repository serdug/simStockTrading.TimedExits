# Simulated Stock Trading - Timed Exits

A concise performance calculation for backtesting (or simulating) stock trading strategies in R. Trade entries by input signals, exits timed for the holding period.

Net asset values are calculated for simulated stock trading by input entry signals and timed exits. The model allows an incrementally rising number of open positions. Each open position is closed once its holding periods lapses. No reinvestment of returns. The proportional (constant) limit of exposure per position applies.

A new ('long' or 'short') position is opened every time (e.g. daily) the signal is 'up' or 'down'. Also the stocks are added to the position while the regime lasts, i.e. the signal remains the same. This model only supports **timed liquidation** of open positions. So, after entering a 'long' or a 'short' position, this position is liquidated when the established number of holding periods (such as trade days) passes. However, the daily turnover (and hence the sum of broker's commissions) corresponds the difference between the quantities of added and removed stocks.

Therefore, the application of the timed exits, along with the proportional limit per position, may help to smooth results reducing the significance of outliers, as the exposure may gradually build up and decrease following the 'up' and 'down' signals.


## Settings

Use `params.yaml` to set the following parameters:

* `path` (character) - a path to data (`a/path/to/inputs/`)
* `input` (character) - a list (vector) of short names (`name.csv`) of CSV files with signals
* `output` (character) - a list (vector) of full names (`a/path/to/output-file.csv`) of CSV files for results, which should be of the same length as the input list
* `keep` (integer) - a number of holding days, periods or bars before a position is liquidated
* `comm` (numeric) - broker's commission payable when a stock is bought or sold
* `cash` (numeric) - cash initially allocated for trading; it is the limit of exposure
* `coef` (numeric or integer) - a list (vector) of coefficients, such as 5 (for 1/5 limit per position held for 5 days), to be multiplied together to calculate the (constant) limit of exposure per position

The coefficients help to respect the total limit of exposure.


## Input Format

The trades are executed on the date of signal. The model takes trade signals in CSV files containing data in the following format (the column names must be respected):

* `Date` (character) - Date, time stamp, period or bar ID
* `H` (numeric) - stock's High price
* `L` (numeric) - stock's Low price
* `C` (numeric) - stock's Close (Last) price
* `T` (numeric) - stock's Trade price, a gross execution price of opening or closing trades
* `Dn` (numeric or integer) - Down, a signal to sell stocks opening a respective number of 'short' positions
* `Up` (numeric or integer) - Up, a signal to buy stocks opening a respective number of 'long' positions


## Output Format

Results are saved in CSV files containing data in the following columns:

* `Date` (character) - Date, time stamp, period or bar ID
* `ClosePx` (numeric) - stock's Close (Last) price
* `TradePx` (numeric) - stock's Trade price
* `SI` (numeric or integer) - the number of opened 'short' positions
* `SO` (numeric or integer) - the number of closed 'short' positions
* `LI` (numeric or integer) - the number of opened 'long' positions
* `LO` (numeric or integer) - the number of closed 'long' positions
* `Assets` (numeric) - calculated net asset value


## Running

After setting parameters, source `results.R`.


## Dependencies

Packages:

* `yaml` to convert contents of a YAML file into an R object
* `magrittr` for a forward-pipe operator (%>%)
