//
//  CoinDeskClient.swift
//  BCEXRate
//
//  Created by Juho Pispa on 12.8.2016.
//  Copyright © 2016 Juho Pispa. All rights reserved.
//

import Foundation

class CoinDeskClient {
    
    let baseUrl:String = "https://api.coindesk.com/v1/bpi/"
    let currencyParam:String = "?currency=EUR"
    
    func fetchLast28(completion: [String:Double] ->()) {
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = Constants.DateFormatForApi
        
        let fromDate = NSDate().dateByAddingTimeInterval(-27*24*60*60)
        let fromDateString = dateFormatter.stringFromDate(fromDate)
        
        let toDate = NSDate().dateByAddingTimeInterval(-1*24*60*60)
        let toDateString:String = dateFormatter.stringFromDate(toDate)
        
        let paramsString = "historical/close.json?\(currencyParam)&start=\(fromDateString)&end=\(toDateString)"
        
        let urlString = baseUrl + paramsString
        
        let url:NSURL = NSURL(string: urlString)!
        
        getRequestWithUrl(url, history: true) { bpis in
            completion(bpis)
        }
    }
    
    func fetchCurrent(completion: [String:Double] ->()) {
        let urlString = "\(baseUrl)currentprice/EUR.json?"
        let url:NSURL = NSURL(string: urlString)!
        
        getRequestWithUrl(url, history: false) { rate in
            completion(rate)
        }
    }
    
    func getRequestWithUrl(url: NSURL, history: Bool, completion: [String:Double] ->()) {
        
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
                    
                    let json = try NSJSONSerialization.JSONObjectWithData(data!,
                                options:NSJSONReadingOptions()) as? [String : AnyObject]
                    
                    if(history) {
                        let bpis = json!["bpi"] as? [String : Double]
                        completion(bpis!)
                    }
                    else {
                        let bpiDict = json!["bpi"] as? [String : AnyObject]
                        let eurBpiDict = bpiDict!["EUR"] as? [String : AnyObject]
                        let rate = eurBpiDict!["rate_float"] as! Double
                        let rateDict = ["rate_float" : rate]
                        completion(rateDict)
                    }
                    
                    
                    
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