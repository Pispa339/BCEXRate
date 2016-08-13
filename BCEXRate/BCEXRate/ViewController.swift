//
//  ViewController.swift
//  BCEXRate
//
//  Created by Juho Pispa on 12.8.2016.
//  Copyright © 2016 Juho Pispa. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var graphView: GraphView!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let cdClient:CoinDeskClient = CoinDeskClient()
        
        cdClient.fetchLast28() { bpis in
            let sortedKeys = Array(bpis.keys).sort(<)
            var sortedValues = [Float]()
            
            for key in sortedKeys {
                sortedValues.append(bpis[key]!)
            }
            
            //self.graphView.populateGraphWithValues(sortedValues)
            //self.graphView.drawRect(graphView.rect)
            self.setupGraphDisplay(sortedValues)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupGraphDisplay(values: [Float]) {
        
        //Use 7 days for graph - can use any number,
        //but labels and sample data are set up for 7 days
        let noOfDays:Int = 27
        
        //1 - replace last day with today's actual data
        //graphView.graphPoints[graphView.graphPoints.count-1] = values
        graphView.graphPoints = values;
        
        //2 - indicate that the graph needs to be redrawn
        graphView.setNeedsDisplay()
        
        //maxLabel.text = "\(maxElement(graphView.graphPoints))"
        
        //3 - calculate average from graphPoints
//        let average = graphView.graphPoints.reduce(0, combine: +)
//            / graphView.graphPoints.count
//        averageWaterDrunk.text = "\(average)"
        
        //set up labels
        //day of week labels are set up in storyboard with tags
        //today is last day of the array need to go backwards
        
        //4 - get today's day number
//        let dateFormatter = NSDateFormatter()
//        let calendar = NSCalendar.currentCalendar()
//        let componentOptions:NSCalendarUnit = .CalendarUnitWeekday
//        let components = calendar.components(componentOptions,
//                                             fromDate: NSDate())
//        var weekday = components.weekday
        
        let days = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12",
                    "13", "14", "15", "16", "17", "18", "19", "20", "21", "22",
                    "23", "24", "25", "26", "27"]
        
//        //5 - set up the day name labels with correct day
//        for i in reverse(1...days.count) {
//            if let labelView = graphView.viewWithTag(i) as? UILabel {
//                if weekday == 7 {
//                    weekday = 0
//                }
//                labelView.text = days[weekday--]
//                if weekday < 0 {
//                    weekday = days.count - 1
//                }
//            }
//        }
    }



}

