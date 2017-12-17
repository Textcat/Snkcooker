//
//  genPostData.swift
//  snkcooker
//
//  Created by 刘业臻 on 2017/12/17.
//  Copyright © 2017年 luiyezheng. All rights reserved.
//

import Foundation

public func genShippingPostData(with auth_token:String) -> [String:Any] {
    var data_to_post = [String:Any]()
    data_to_post["utf8"] = "✓"
    data_to_post["_method"] = "patch"
    data_to_post["authenticity_token"] = auth_token
    data_to_post["previous_step"] = "contact_information"
    data_to_post["step"] = "shipping_method"
    data_to_post["checkout[email]"] = "luiyezheng123@gmail.com"
    data_to_post["checkout[shipping_address][first_name]"] = "Zhen"
    data_to_post["checkout[shipping_address][last_name]"] = "Yu"
    data_to_post["checkout[shipping_address][company]"] = ""
    data_to_post["checkout[shipping_address][address1]"] = "828 Jazz CT"
    data_to_post["checkout[shipping_address][address2]"] = "18551629136"
    data_to_post["checkout[shipping_address][city]"] = "San Jose"
    data_to_post["checkout[shipping_address][country]"] = "United States"
    data_to_post["checkout[shipping_address][province]"] = "California"
    data_to_post["checkout[shipping_address][zip]"] = "95134"
    data_to_post["checkout[shipping_address][phone]"] = "(408) 513-6565"
    data_to_post["button"] = ""
    data_to_post["checkout[client_details][browser_width]"] = "1170"
    data_to_post["checkout[client_details][browser_height]"] = "711"
    data_to_post["checkout[client_details][javascript_enabled]"] = "1"
    
    return data_to_post
}
