//
//  captchaSolver.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/17.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Foundation
import Alamofire

internal class CapSolver {
    let siteKey = "6LeoeSkTAAAAAA9rkZs5oS82l69OEYjKRZAiKdaF"
    let authKey = "c2fd8111e8359547c83c56c657ade515"
    var taskID : Int?
    var pUrl : String
    var gresponse : String?
    
    init?(pUrl:String) {
        self.pUrl = pUrl
    }
    
    internal func startSolve(completion:@escaping (_ solution:String) -> Void) {
        let url = "https://api.anti-captcha.com/createTask"
        let postData:[String:Any] = ["clientKey":authKey, "task":["type":"NoCaptchaTaskProxyless","websiteURL":pUrl, "websiteKey":siteKey]]
        
        Alamofire.request(url, method: .post, parameters: postData, encoding: JSONEncoding.default).responseJSON{response in
            if let json = response.result.value as? [String:Any] {
                self.taskID = json["taskId"] as? Int
                self.getResult(completion: completion)
            }
        }
    }
    
    private func getResult(completion:@escaping (_ solution:String) -> Void) {
        guard let id = taskID else {return}
        let postData:[String:Any] = ["clientKey":authKey,
                                     "taskId":id]
        
        let url = "https://api.anti-captcha.com/getTaskResult"
        
        Alamofire.request(url, method: .post, parameters: postData, encoding: JSONEncoding.default).responseJSON{response in
            if let json = response.result.value as? [String:Any] {
                if Array(json.keys).contains("solution"),let solution:[String:String] = json["solution"] as? [String:String] {
                    guard let response = solution["gRecaptchaResponse"] else {return}
                    completion(response)
                }else {
                    print(json)
                    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1), execute: {
                        self.getResult(completion: completion)
                    })
                }
            }
        }
    }
}

