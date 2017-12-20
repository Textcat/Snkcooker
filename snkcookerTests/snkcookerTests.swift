//
//  snkcookerTests.swift
//  snkcookerTests
//
//  Created by 刘业臻 on 2017/12/18.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import XCTest
//@testable import snkcooker

class snkcookerTests: XCTestCase {
    let path = NSHomeDirectory()+"/snkcooker/userconfig.plist"
    let fileManager = FileManager.default
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPlistReader() {
    }
    
    func testCheckfile() {
        print(path)
        if !fileManager.fileExists(atPath: path) {
            print("File not exist!")
            
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
    
    func testPlistWriter() {
        let dict = NSMutableDictionary(contentsOfFile: path)
        let type = "Emails"
        
        var old_emails = dict![type] as! Array<String>
        
        old_emails.append("luiyezheng@qq.com")
        
        dict?.setValue(old_emails, forKey: "Emails")
        dict?.write(toFile: path, atomically: true)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
