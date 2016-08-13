//
//  CoinDeskClient.swift
//  BCEXRate
//
//  Created by Juho Pispa on 12.8.2016.
//  Copyright © 2016 Juho Pispa. All rights reserved.
//

import Foundation

class CoinDeskClient {
    
    let baseUrl:String = "https://api.coindesk.com/v1/bpi"
    let currencyParam:String = "?currency=EUR"
    let dateFormat = "yyyy-MM-dd"
    
    func fetchLast28() {
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = dateFormat
        
        let fromDate = NSDate().dateByAddingTimeInterval(-28*24*60*60)
        let fromDateString = dateFormatter.stringFromDate(fromDate)
        
        let toDate = NSDate().dateByAddingTimeInterval(-1*24*60*60)
        let toDateString:String = dateFormatter.stringFromDate(toDate)
        
        let paramsString = "/historical/close.json?\(currencyParam)&start=\(fromDateString)&end=\(toDateString)"
        
        let urlString = baseUrl + paramsString
        
        let url:NSURL = NSURL(string: urlString)!
        
        getRequestWithUrl(url)
    }
    
    func fetchCurrent() {
        let current:String = "currentprice/EUR.json"
    }
    
    func getRequestWithUrl(url: NSURL) {
        
        let session = NSURLSession.sharedSession()
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        request.cachePolicy = NSURLRequestCachePolicy.UseProtocolCachePolicy
        
        let task = session.dataTaskWithRequest(request) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                do {
                    
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options:.AllowFragments)
                    let perse = 0
                    
                } catch {
                    print("Error fetching JSON")
                }
            }
        }
        
        task.resume()
    }
    
//    func getCurrenciesFromDict(dict: [String: AnyObject]) -> [String: String] {
//        
//        
//        return dict
//    }
    
    
}