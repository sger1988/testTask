//
//  Sequence.swift
//  GitHubReposTask
//
//  Created by Sergey Gerashchenko on 4/6/18.
//  Copyright © 2018 Sergey Gerashchenko. All rights reserved.
//

import Foundation

class Sequence {
  
  static let shared = Sequence()
  
  private init() {}
  
  private var value: Int = 0
  
  func generateValue() -> NSNumber {
    let result = value
    value += 1
    
    return NSNumber.init(value: result)
  }

}
