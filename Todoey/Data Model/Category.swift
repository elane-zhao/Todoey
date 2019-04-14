//
//  Category.swift
//  Todoey
//
//  Created by Xinyi Zhao on 4/5/19.
//  Copyright © 2019 Xinyi Zhao. All rights reserved.
//

import Foundation
import RealmSwift

class Category: Object {
    @objc dynamic var name: String = ""
    
    @objc dynamic var hexColor: String = ""
    
    let items = List<Item>()
    
}
