//
//  models.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/17.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Foundation

struct BotTarget {
    let site:Site
    var quantity:Int
    var size:Double
}

typealias emails = [Dictionary<String, String>]

struct EmailsData {
    var values:emails
    
    init() {
        let array = PlistDicManager.readPlistObject(withkey: "Emails") as! emails
        self.values = array
    }
}

public enum Site : String {
    case rockcitykicks = "https://rockcitykicks.com"
    case exclucitylife = "https://shop.exclucitylife.com"
    case yeezysupply = "https://yeezysupply.com"
    case notre = "https://www.notre-shop.com"
    case bowsandarrows = "https://www.bowsandarrowsberkeley.com"
    case shoegallerymiami = "https://shoegallerymiami.com"
}
