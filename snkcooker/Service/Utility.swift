//
//  Utility.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/17.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Foundation

private enum MyError : Error {
    case InvalidPostData
}

public class Utility {
    static func genPostRequest(from url:URL,with postData:[String:Any])-> URLRequest? {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let httpBody = try JSONSerialization.data(withJSONObject: postData, options: [])
            
            request.httpBody = httpBody
            return request
        }catch {
            return nil
        }
    }
}
