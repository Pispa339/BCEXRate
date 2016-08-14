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
    var currencyParam:String = "?currency=EUR"
    
    //fetches historical data for the desired date range
    func fetchRange(fromDate: NSDate, toDate: NSDate, completion: [String:Double] ->()) {

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = Constants.DateFormatForApi
        
        //TODO: safeguards/input validation
        let fromDateString = dateFormatter.stringFromDate(fromDate)
        let toDateString:String = dateFormatter.stringFromDate(toDate)
        
        let paramsString = "historical/close.json?\(currencyParam)&start=\(fromDateString)&end=\(toDateString)"
        
        let urlString = baseUrl + paramsString
        
        let url:NSURL = NSURL(string: urlString)!
        
        getRequestWithUrl(url, history: true) { data in
            let bpiData = data["bpi"] as? [String : Double]
            completion(bpiData!)
        }
    }
    
    func setCurrencyParam(currencyCode: String) {
        currencyParam = "?currency=\(currencyCode)"
    }
    
    //fetches current exchange rate
    func fetchCurrent(completion: [String:Double] ->()) {
        let urlString = "\(baseUrl)currentprice/EUR.json?"
        let url:NSURL = NSURL(string: urlString)!
        
        getRequestWithUrl(url, history: false) { data in
            //completion(rate)
            let bpiDict = data["bpi"] as? [String : AnyObject]
            let eurBpiDict = bpiDict!["EUR"] as? [String : AnyObject]
            let rate = eurBpiDict!["rate_float"] as! Double
            let rateDict = ["rate_float" : rate]
            completion(rateDict)
        }
    }
    
    //semi-general GET-request function for fetching exchange rate data
    func getRequestWithUrl(url: NSURL, history: Bool, completion: [String:AnyObject] ->()) {
        
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
                    
                    completion(json!)
                    
                } catch {
                    print("Error fetching JSON")
                }
            }
        }
        
        task.resume()
    }    
    
}