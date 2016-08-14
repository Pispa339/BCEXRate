$BCEXRate
========

$BCEXRate is an application to show the Bitcoins exchange rate (Bitcoin/EUR) in a graph.

Made with swift.

The application uses cocoapods to load Daniel Gindi’s Charts framework to be utilized as the chart.
(https://github.com/danielgindi/Charts)


Features
--------

- Fetches the historical data for the last 4 weeks up to today (daily data, 1 value per day)
- Feeds the 28 values into a graph
- Continuously updates the current price for today
- Caches the data to show a graph "last fetched rates" upon app start while fetching new values
- Long pressing on a particular day on the graph flashes its value and date. Also long pressing and dragging to other values is possible

Installation
------------

To install the cocoapods, open the terminal and navigate to the directory with the podfile. After this:

1. $ sudo gem install cocoapods
2. $ pod setup
3. $ pod install
4. open the most recent workspace

Process
-------

1. The application tries checks if there is cached data. If there is, it inits the graph with it. If not, the app presents an activity indicator and a loading text

2. The application creates an instance of the CoinDeskClient, which acts as the communication channel between the app and the Coindesk API

2. The application fetches historical exchange rate data through the CoinDeskClient (last 27 days). After fetching this data, the app fetches todays current exchange rate. The current rate is added to the end of the historical data and the graph is initialized with these values. 

3. The application starts polling current rate with a timer for continuous updating. The graph is updated every time, the current rate is fetched succesfully

Classes
-------
-------

CoinDeskClient
--------------
 
Acts as the communication channel between the app and the Coindesk API.

Functions:

1. fetchRange
	- Fetches the the historical data from the given range asynchronously. Returns the data in a  dictionary with dates (string) as keys and exchange rates (double) as values.

2. fetchCurrent
	- Fetches the current exchange rate of BC asynchronously. Returns the data as a dictionary with a constant string as key and current rate as value (double)

3. getRequestWithUrl
	- Semi-general GET-request function which is used by fetchRange and fetchCurrent. Performs a GET-request with a given URL. Returns a Dictionary with AnyObject as value.


ViewController
--------------

The main view controller of the application. Utilizes Daniel Gindi’s Charts framework as the chart.
(https://github.com/danielgindi/Charts)

1. HandleLongPressGesture
	- Own implementation of longPressGestureHandler, since readymade gesture recognizers of the Charts’s lineChartView weren't suitable for this use-case. Shows the details of a point in graph when pressed. The details are shown in a small ”statusview”.

2. startPollingCurrent
	- Init’s a timer to fetch the current exchange rate and to update it into the graph

3. cacheDataToDefaults
	- Caches the latest graph’s data to user defaults to be loaded while launching the application, while fetching the latest data from the API.

4. populateGraphWithCachedData
	- Inits and populates the graph with the data cached to the user defaults in cacheDataToDefaults -function

5. fetchAndShowData
	- Fetches the exchange rate data of last 28 days. Sorts and formats the data to be used in the graph. Inits the data to the graph to be showed to the user

6. fetchAndUpdateCurrent
	- Fetches the current exchange rate of BC. Updates the graph’s data with the value and updates the graph

7. setUpAndPopulateChart
	- Sets up the chart’s look and options. Init’s the chart with given data.