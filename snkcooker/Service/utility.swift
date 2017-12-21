//
//  Utility.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/17.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Foundation

internal class Utility {
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
    
    static func genUrlencodePostRequest(from url:URL, with postData:[String:Any])-> URLRequest {
        let array:[String] = postData.map {"\(String($0))=\(String(describing: $1))"}
        let pamaraters = array.joined(separator: "&").data(using: .utf8)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = pamaraters
        
        return request
    }
}


internal func += <K, V> (left: inout [K:V], right: [K:V]) {
    for (k, v) in right {
        left[k] = v
    }
}


internal class PlistDicManager{
    static func readPlistObject(withkey key:String) -> Any?{
        let path = NSHomeDirectory()+"/snkcooker/userconfig.plist"
        guard let dict = NSMutableDictionary(contentsOfFile: path) else {return nil}
        guard let object = dict[key] else {return nil}
        
        return object
    }
    
    
    static func writePlistObject(object:Any,forKey:String) {
        let path = NSHomeDirectory()+"/snkcooker/userconfig.plist"
        let dict = NSMutableDictionary(contentsOfFile: path)
        
        dict?.setValue(object, forKey: forKey)
        dict?.write(toFile: path, atomically: true)
    }
    
    
    static func updatePlistObject(forKey key:String, process:(_ object:Any) -> Any?) {
        if let object = self.readPlistObject(withkey: key){
            if let newObject = process(object) {
                self.writePlistObject(object: newObject, forKey: key)
            }
        }
    }
    
    
    static func checkExist() {
        let path = NSHomeDirectory()+"/snkcooker/userconfig.plist"
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            
            do {
                try fileManager.createDirectory(atPath: NSHomeDirectory()+"/snkcooker", withIntermediateDirectories: true, attributes:nil)
                
                let srcPath = Bundle.main.path(forResource: "userconfig", ofType: "plist")
                
                do {
                    //Copy the project plist file to the documents directory.
                    try fileManager.copyItem(atPath: srcPath!, toPath: path)
                } catch {
                    print("File copy error!")
                }
            }catch {
                print("create directory fail")
            }
        }
    }
}
