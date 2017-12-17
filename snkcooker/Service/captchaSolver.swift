//
//  captchaSolver.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/17.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Foundation

public class CapSolver {
    let site_key : String
    let auth_key : String
    var task_id : Int?
    var pUrl : String
    var gresponse : String?
    
    
    init?(site_key:String, pUrl:String, auth_key:String) {
        self.site_key = site_key
        self.auth_key = auth_key
        self.pUrl = pUrl
    }
    
    
    public func getRespose(){
        let post_data:[String:Any] = ["clientKey":self.auth_key, "task":["type":"NoCaptchaTaskProxyless","websiteURL":self.pUrl, "websiteKey":self.site_key]]
        let request = Utility.genPostRequest(from: URL(string: "https://api.anti-captcha.com/createTask")!, with: post_data)
        let data_task = URLSession.shared.dataTask(with: request!) {(data, response, error) in
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    if let object = json as? [String: Any] {
                        self.task_id = object["taskId"] as? Int
                        self.solveCap()
                    }
                }catch {
                    print(error)
                }
            }
        }
        data_task.resume()
    }
    
    
    private func postRequest(with request:URLRequest) {
        _ = URLSession.shared.dataTask(with: request) {(data, response, error) in
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    if let object = json as? [String: Any] {
                        if Array(object.keys).contains("solution") {
                            let solution:[String:String] = object["solution"] as! [String:String]
                            self.gresponse = solution["gRecaptchaResponse"]!
                        }else {
                            print(object)
                            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2), execute: {
                                self.postRequest(with: request)
                            })
                        }
                    }
                }catch {
                    print(error)
                }
            }
            }.resume()
    }
    
    
    private func solveCap(){
        let postData:[String:Any] = ["clientKey":self.auth_key,
                                        "taskId":self.task_id!]
        let request = Utility.genPostRequest(from: URL(string:"https://api.anti-captcha.com/getTaskResult")!, with: postData)
        self.postRequest(with: request!)
    }
}

