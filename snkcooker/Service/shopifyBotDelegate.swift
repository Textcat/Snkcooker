//
//  shopifyBotDelegate.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/23.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Foundation

protocol ShopifyBotDelegate {
    func productDidCheckedout()
    
    func productDidAddedtoCart()
}
