//
//  snkcookerTests.swift
//  snkcookerTests
//
//  Created by 刘业臻 on 2017/12/18.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import XCTest
@testable import snkcooker

class snkcookerTests: XCTestCase {
    var bot:ShopifyBot?
    var newTarget:BotTarget?
    
    override func setUp() {
        super.setUp()
        
        self.newTarget = BotTarget(site: "https://www.a-ma-maniere.com", quantity: 2, size: 8)
        self.bot = ShopifyBot(target: newTarget!)
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testProductInfo() {
        let expectation = XCTestExpectation(description: "Download apple.com home page")

        self.bot?.productInfo(product_url: "https://www.a-ma-maniere.com/products/nike-air-max-1-obsidian-white-navy-red")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
