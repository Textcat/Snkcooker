//
//  Utility.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/17.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Foundation
import Alamofire

internal class RetryHandler:RequestRetrier {
    public func should(_ manager: SessionManager,
                       retry request: Request,
                       with error: Error,
                       completion: @escaping RequestRetryCompletion)
    {
        if let task = request.task,
            let response = task.response as? HTTPURLResponse,
            response.statusCode != 400,
            response.statusCode != 404
        {
            completion(true, 1.0) // retry after 1 second
        } else {
            completion(false, 0.0) // don't retry
        }
    }
}


internal func += <K, V> (left: inout [K:V], right: [K:V]) {
    for (k, v) in right {
        left[k] = v
    }
}

extension Data {
    var html:String {
        return String(describing: NSString(data: self, encoding: String.Encoding.utf8.rawValue))
    }
}
typealias Keywords = (Array<String>,Array<String>)

extension String {
    internal func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        
        return emailTest.evaluate(with: self)
    }
    
    internal func isValidSize() -> Bool {
        let sizeRegex = "([0-9]|1[0-9])((.[5]){1})?"
        let sizeTest = NSPredicate(format: "SELF MATCHES %@", sizeRegex)
        
        return sizeTest.evaluate(with: self)
    }
    
    internal func isValidKeywords() -> Bool {
        let kwdRegex = "((\\+|\\-)[^\\+\\-]+)+"
        let kwdTest = NSPredicate(format: "SELF MATCHES %@", kwdRegex)
        
        return kwdTest.evaluate(with: self)
    }
    
    internal func keywords() -> Keywords{
        var positiveKeywords:Array<String> = []
        var negativeKeywords:Array<String> = []
        // (1):
        let positivePat = "(?<=\\+)([a-zA-Z]+)"
        let negativePat = "(?<=\\-)([a-zA-Z]+)"
        // (3):
        let positiveRegex = try! NSRegularExpression(pattern: positivePat, options: [])
        let negativeRegex = try! NSRegularExpression(pattern: negativePat, options: [])
        // (4):
        let positiveMatchs = positiveRegex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
        let negativeMatchs = negativeRegex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
        
        for match in positiveMatchs {
            if let range = Range(match.range, in:self) {
                let newKeyword = String(self[range])
                positiveKeywords.append(newKeyword)
            }
        }
        
        for match in negativeMatchs {
            if let range = Range(match.range, in:self) {
                let newKeyword = String(self[range])
                negativeKeywords.append(newKeyword)
            }
        }
        
        return (positiveKeywords, negativeKeywords)
    }
}

internal class PlistDicManager{
    static let path = NSHomeDirectory()+"/snkcooker/userconfig.plist"
    
    static func allPlistObject() -> NSMutableDictionary? {
        guard let dict = NSMutableDictionary(contentsOfFile: path) else {return [:]}
        
        return dict
    }
    
    static func readPlistObject(withkey key:String) -> Any?{
        guard let dict = NSMutableDictionary(contentsOfFile: path) else {return nil}
        guard let object = dict[key] else {return nil}
        
        return object
    }
    
    
    static func writePlistObject(object:Any,forKey:String) {
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
