//
//  CoinDeskClient.swift
//  BCEXRate
//
//  Created by Juho Pispa on 12.8.2016.
//  Copyright © 2016 Juho Pispa. All rights reserved.
//

import Foundation

class CoinDeskClient {
    
    let baseUrl:String = "http(s)://api.coindesk.com/v1"
    let dateFormat = "YYYY-MM-DD"
    
    func fetchData() {
        let url:NSURL = NSURL(string: baseUrl)!
        let session = NSURLSession.sharedSession()
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        request.cachePolicy = NSURLRequestCachePolicy.UseProtocolCachePolicy
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = dateFormat
        
        let fromDate = NSDate().dateByAddingTimeInterval(-28*24*60*60)
        let fromDateString = dateFormatter.stringFromDate(fromDate)
        
        let toDateString:String = dateFormatter.stringFromDate(NSDate())
        
        let task = session.dataTaskWithRequest(request) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                do {
                
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options:.MutableContainers)
             
                } catch {
                    print("Error fetching JSON")
                }
            }
        }
        
        task.resume()
//        let request = NSURLRequest(URL: url!, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 20)
//        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue(), completionHandler:{
//            (response: NSURLResponse?, data: NSData?, error: NSError?)-> Void in
//            
//            // Get data as string
//            let str = NSString(data: data!, encoding: NSUTF8StringEncoding)
//            print(str)
//            })
    }
    
}