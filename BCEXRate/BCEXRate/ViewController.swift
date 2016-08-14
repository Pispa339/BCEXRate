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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.storeDataBeforeQuitting), name: UIApplicationDidEnterBackgroundNotification, object: nil)

        lineChartView.delegate = self
        detailView.layer.cornerRadius = 8.0
        
        // Do any additional setup after loading the view, typically from a nib.
        lineChartView.noDataText = "No data to show"
        lineChartView.noDataTextDescription = "Fetching data from the server..."
        
        populateGraphWithCachedData()
        
        lineChartView.highlightPerDragEnabled = true;
        lineChartView.pinchZoomEnabled = false;
        //lineChartView.dragEnabled = false;
        lineChartView.highlightPerTapEnabled = false;
        //lineChartView.chartfil
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(_:)))
        lineChartView.addGestureRecognizer(panGesture)
        
        fetchAndShowData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: ChartHighlight) {
//        detailView.hidden = false
//        valueDetailLabel.text = "\(graphValues[entry.xIndex])"
//        dateDetailLabel.text = "\(graphDataPoints[entry.xIndex])"
    }
    
    func handlePanGesture(panGesture: UIPanGestureRecognizer) {
        if (panGesture.state == UIGestureRecognizerState.Ended) {
            detailView.hidden = true
        }
        else if (panGesture.state == UIGestureRecognizerState.Changed ||
                    panGesture.state == UIGestureRecognizerState.Began) {
            
            
            //lineChartView.
//            var closestXval
            for entry in (lineChartView.data?.dataSets[0])! {
                
            }
            detailView.hidden = false
//            valueDetailLabel.text = "\(graphValues[entry.xIndex])"
//            dateDetailLabel.text = "\(graphDataPoints[entry.xIndex])"
        }
    }
    
    func chartValueNothingSelected(chartView: ChartViewBase) {
        detailView.hidden = true
    }
    
    func startPollingCurrent() {
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(self.fetchAndUpdateCurrent), userInfo: nil, repeats: true)
    }
    
    func storeDataBeforeQuitting() {
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
        let fromDate = NSDate().dateByAddingTimeInterval(-27*24*60*60)
        let toDate = NSDate().dateByAddingTimeInterval(-1*24*60*60)

        graphValues = [Double]()
        graphDataPoints = [String]()
        
        cdClient.fetchRange(fromDate, toDate: toDate) { bpis in
            let sortedKeys = Array(bpis.keys).sort(<)
            
            for key in sortedKeys {
                self.graphValues.append(bpis[key]!)
            }
            
            //make the dateformat more suitable for graph's use
            let dateFormatter = NSDateFormatter()
            for dateString in sortedKeys {
                dateFormatter.dateFormat = Constants.DateFormatForApi
                let dateAsDate = dateFormatter.dateFromString(dateString)
                
                dateFormatter.dateFormat = "dd.MM"
                let newDateString = dateFormatter.stringFromDate(dateAsDate!)
                self.graphDataPoints.append(newDateString)
            }
            
            //add todays data as well
            self.cdClient.fetchCurrent() { rate in
                let thisDateString = dateFormatter.stringFromDate(NSDate())
                self.graphDataPoints.append(thisDateString)
                self.graphValues.append(rate["rate_float"]!)
                
                self.setUpAndPopulateChart(self.graphDataPoints, values: self.graphValues)
                
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
        }
    }
    
    func setUpAndPopulateChart(dataPoints: [String], values: [Double]) {
        
        lineChartView.autoScaleMinMaxEnabled = true;
        lineChartView.descriptionText = "BPI's of the last 28 days"
        if(lineChartView.isEmpty()) {
            lineChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
        }
        
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<dataPoints.count {
            let dataEntry = ChartDataEntry(value: values[i], xIndex: i)
            dataEntries.append(dataEntry)
        }
        
        var colors: [UIColor] = []
        
        for _ in 0..<dataPoints.count {
            let red = Double(arc4random_uniform(256))
            let green = Double(arc4random_uniform(256))
            let blue = Double(arc4random_uniform(256))
            
            let color = UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1)
            colors.append(color)
        }
        
        
        let lineChartDataSet = LineChartDataSet(yVals: dataEntries, label: "BPI")
//        let backgroundGradient = createGradient(UIColor.grayColor(), endColor: UIColor.clearColor())
//        lineChartView.backgroundColor = backgroundGradient
        
        let fillGradient = createGradient(UIColor.redColor(), endColor: UIColor.clearColor())
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
        let gradientColors = [startColor.CGColor, endColor.CGColor] // Colors of the gradient
        let colorLocations:[CGFloat] = [1.0, 0.0] // Positioning of the gradient
        let gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), gradientColors, colorLocations)
        return gradient!
    }
    
}