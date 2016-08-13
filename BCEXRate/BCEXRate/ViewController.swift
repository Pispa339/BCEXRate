//
//  ViewController.swift
//  BCEXRate
//
//  Created by Juho Pispa on 12.8.2016.
//  Copyright © 2016 Juho Pispa. All rights reserved.
//

import UIKit
import Charts

class ViewController: UIViewController {

    @IBOutlet weak var graphView: GraphView!
    @IBOutlet weak var lineChartView: LineChartView!
    
    var graphValues = [Double]()
    var graphDataPoints = [String]()
    
    let valuesCacheKey:String = "graphValues"
    let dataPointsCacheKey:String = "graphDataPoints"
    
    let cdClient:CoinDeskClient = CoinDeskClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "storeDataBeforeQuitting", name: UIApplicationDidEnterBackgroundNotification, object: nil)

        let defaults = NSUserDefaults.standardUserDefaults()
        graphValues = (defaults.objectForKey(valuesCacheKey) as? [Double])!
        graphDataPoints = defaults.objectForKey(dataPointsCacheKey) as? [String]!
        setUpAndPopulateChart(graphDataPoints, values: graphValues)
        //cdClient = CoinDeskClient()
        // Do any additional setup after loading the view, typically from a nib.
        lineChartView.noDataText = "No data to show"
        lineChartView.noDataTextDescription = "Fetching data from the server..."
        
        fetchAndShowData()
        //start updating the last value
        let timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(self.fetchAndUpdateCurrent), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func storeDataBeforeQuitting() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(self.graphValues, forKey: valuesCacheKey)
        defaults.setObject(self.graphDataPoints, forKey: dataPointsCacheKey)
    }
    
    func fetchAndShowData() {
        
        cdClient.fetchLast28() { bpis in
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
            }
        }
    }
    
    func fetchAndUpdateCurrent() {
        cdClient.fetchCurrent() { rate in
            let dataset = self.lineChartView.data?.getDataSetByIndex(0)
            let index = dataset?.entryCount
            let valueToAdd = rate["rate_float"]
            let entry = ChartDataEntry(value: valueToAdd!, xIndex: index!)
            dataset?.removeLast()
            dataset?.addEntry(entry)
            //self.lineChartView.data.
            self.graphValues[self.graphValues.count] = valueToAdd!
            self.lineChartView.notifyDataSetChanged()
        }
    }
    
    func setUpAndPopulateChart(dataPoints: [String], values: [Double]) {
        
        lineChartView.autoScaleMinMaxEnabled = true
        lineChartView.descriptionText = "BPI's of the last 28 days"
        lineChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
        
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
        let lineChartData = LineChartData(xVals: dataPoints, dataSet: lineChartDataSet)
        lineChartView.data = lineChartData
    }
    
}