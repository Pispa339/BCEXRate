//
//  ViewController.swift
//  BCEXRate
//
//  Created by Juho Pispa on 12.8.2016.
//  Copyright © 2016 Juho Pispa. All rights reserved.
//

import UIKit
import Charts

class ViewController: UIViewController, ChartViewDelegate {

    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var fetchingActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var valueDetailLabel: UILabel!
    @IBOutlet weak var dateDetailLabel: UILabel!
    
    
    var graphValues = [Double]()
    var graphDataPoints = [String]()
    
    let valuesCacheKey:String = "graphValues"
    let dataPointsCacheKey:String = "graphDataPoints"
    
    let cdClient:CoinDeskClient = CoinDeskClient()
    
    var pollingTimer:NSTimer = NSTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchingActivityIndicator.startAnimating()
        detailView.layer.cornerRadius = 8.0
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.cacheDataToDefaults), name: UIApplicationDidEnterBackgroundNotification, object: nil)

        lineChartView.delegate = self
        
        lineChartView.noDataText = "No data to show"
        lineChartView.noDataTextDescription = "Fetching data from the server..."
        
        populateGraphWithCachedData()
        
        //Own implementation of longPressGesture
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPressGesture(_:)))
        lineChartView.addGestureRecognizer(longPressGesture)
        
        fetchAndShowData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /* 
     * Own implementation of longPressGestureHandler, since readymade gesture
     * recognizers weren't suitable for this use-case.
     * Shows the details of a point in graph when pressed
     */
    func handleLongPressGesture(longPressGesture: UIPanGestureRecognizer) {
        
        if (longPressGesture.state == UIGestureRecognizerState.Ended) {
            detailView.hidden = true
        }
        else if (longPressGesture.state == UIGestureRecognizerState.Changed ||
                    longPressGesture.state == UIGestureRecognizerState.Began) {
            detailView.hidden = false

            let transformer = lineChartView.getTransformer(ChartYAxis.AxisDependency.Right)
            
            //transforms the current touchPoint to values in chart
            let point = transformer.getValueByTouchPoint(longPressGesture.locationInView(lineChartView))
            
            var value = Double(point.y)
            
            //simple safeguards
            if(value > lineChartView.data?.getYMax()) {
                value = (lineChartView.data?.getYMax())!
            }
            else if(value < lineChartView.data?.getYMin()) {
                value = (lineChartView.data?.getYMin())!
            }
            
            let valueAsString:String = String(format:"%.2f", point.y)
            var dateIndex = Int(point.x)
            
            //dumb safeguards, don't have enough of time to implement better / more dynamic ones
            if(dateIndex > 27) {
                dateIndex = 27
            }
            else if(dateIndex < 0) {
                dateIndex = 0
            }
            let dateAsString = graphDataPoints[dateIndex]
            
            valueDetailLabel.text = valueAsString
            dateDetailLabel.text = dateAsString
        }
    }
    
    func startPollingCurrent() {
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(self.fetchAndUpdateCurrent), userInfo: nil, repeats: true)
    }
    
    func cacheDataToDefaults() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(self.graphValues, forKey: valuesCacheKey)
        defaults.setObject(self.graphDataPoints, forKey: dataPointsCacheKey)
    }
    
    func populateGraphWithCachedData() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let temp = defaults.arrayForKey(valuesCacheKey) as? [Double] {
            graphValues = temp
        }
        if let temp = defaults.stringArrayForKey(dataPointsCacheKey) {
            graphDataPoints = temp
        }
        
        if(!graphValues.isEmpty && !graphDataPoints.isEmpty) {
            setUpAndPopulateChart(graphDataPoints, values: graphValues)
        }
    }
    
    func fetchAndShowData() {
        //parameter/input dates, hardcoded for this use-case
        let fromDate = NSDate().dateByAddingTimeInterval(-27*24*60*60)
        let toDate = NSDate().dateByAddingTimeInterval(-1*24*60*60)

        graphValues = [Double]()
        graphDataPoints = [String]()
        
        //fetch the historical datab of previous 27 days
        cdClient.fetchRange(fromDate, toDate: toDate) { bpis in
            
            /*
             * Need to sort the keys to have them in the correct order for the graph
             * since API doesn't return the values in the needed order
             */
            let sortedKeys = Array(bpis.keys).sort(<)
            
            for key in sortedKeys {
                self.graphValues.append(bpis[key]!)
            }
            
            //make the dateformat more suitable/readable for graph's use
            let dateFormatter = NSDateFormatter()
            for dateString in sortedKeys {
                dateFormatter.dateFormat = Constants.DateFormatForApi
                let dateAsDate = dateFormatter.dateFromString(dateString)
                
                dateFormatter.dateFormat = "dd.MM"
                let newDateString = dateFormatter.stringFromDate(dateAsDate!)
                self.graphDataPoints.append(newDateString)
            }
            
            // fetch and add todays data as well
            self.cdClient.fetchCurrent() { rate in
                let thisDateString = dateFormatter.stringFromDate(NSDate())
                self.graphDataPoints.append(thisDateString)
                self.graphValues.append(rate["rate_float"]!)
                
                self.setUpAndPopulateChart(self.graphDataPoints, values: self.graphValues)
                
                //start polling/updating current value
                if(!self.pollingTimer.valid) {
                    self.startPollingCurrent()
                }
            }
        }
    }
    
    func fetchAndUpdateCurrent() {
        cdClient.fetchCurrent() { rate in
            let dataset = self.lineChartView.data?.getDataSetByIndex(0)
            let index = (dataset?.entryCount)!-1
            let valueToAdd = rate["rate_float"]
            let entry = ChartDataEntry(value: valueToAdd!, xIndex: index)
            dataset?.removeLast()
            dataset?.addEntry(entry)
            self.graphValues[self.graphValues.count - 1] = valueToAdd!
            self.lineChartView.notifyDataSetChanged()
            //the UIApplicationDidEnterBackgroundNotification doesn't seem to be reliable enough
            //hence storing data after every update, which should not be neccessary
            self.cacheDataToDefaults()
//            let valueToAdd = rate["rate_float"]
//            self.graphValues.removeLast()
//            self.graphValues.append(valueToAdd!)
//            self.setUpAndPopulateChart(self.graphDataPoints, values: self.graphValues)
        }
    }
    
    //wouldn't really need parameters in this implementation, but makes it more general
    func setUpAndPopulateChart(dataPoints: [String], values: [Double]) {
        
        //setup charts behaviour
        lineChartView.highlightPerDragEnabled = true;
        lineChartView.pinchZoomEnabled = false;
        lineChartView.dragEnabled = false;
        lineChartView.highlightPerTapEnabled = false;
        lineChartView.drawMarkers = false;
        //This doesn't seem to be working when updating data
        lineChartView.autoScaleMinMaxEnabled = true;
        lineChartView.descriptionText = "BPI's of the last 28 days"
        
        //animate only on launch
        if(lineChartView.isEmpty()) {
            lineChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
        }
        
        //init data for graph from fetched data
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<dataPoints.count {
            let dataEntry = ChartDataEntry(value: values[i], xIndex: i)
            dataEntries.append(dataEntry)
        }
        
        //init the look of the dataset
        let lineChartDataSet = LineChartDataSet(yVals: dataEntries, label: "BPI")
        
        lineChartDataSet.circleRadius = 3.5
        lineChartDataSet.setCircleColor(UIColor.darkGrayColor())
        lineChartDataSet.setColor(UIColor.grayColor().colorWithAlphaComponent(0.7))
        
        let fillGradient = createGradient(UIColor.purpleColor(), endColor: UIColor.clearColor())
        lineChartDataSet.fill = ChartFill.fillWithLinearGradient(fillGradient, angle: 90.0) // Set the Gradient
        lineChartDataSet.drawFilledEnabled = true
        
        let lineChartData = LineChartData(xVals: dataPoints, dataSet: lineChartDataSet)
        lineChartView.data = lineChartData
        
        dispatch_async(dispatch_get_main_queue()) {
            self.fetchingActivityIndicator.stopAnimating()
        }
        self.lineChartView.notifyDataSetChanged()
    }
    
    func createGradient(startColor: UIColor, endColor: UIColor) -> CGGradient {
        let gradientColors = [startColor.CGColor, endColor.CGColor]
        let colorLocations:[CGFloat] = [1.0, 0.0]
        let gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), gradientColors, colorLocations)
        return gradient!
    }
    
}