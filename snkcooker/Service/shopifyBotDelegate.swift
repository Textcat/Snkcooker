//
//  shopifyBotDelegate.swift
//  snkcooker
//
//  Created by luiyezheng on 2017/12/23.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Foundation

protocol ShopifyBotDelegate {
    func productWillFound(id:String)
    func productDidFound(id:String, productName:String)
    func productDidFoundMorethanOne(id:String)
    func productNotFoundYet(id:String)
    func productOutOfStock(id:String)
    func productDidAddedtoCart(id:String)
    func productDidCheckedout(id:String,url:URL)
    
}

extension ShopifyBotDelegate {
    func productNotFoundYet(id:String) {
        
    }
}
