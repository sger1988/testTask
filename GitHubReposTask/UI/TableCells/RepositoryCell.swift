//
//  RepositoryCell.swift
//  GitHubReposTask
//
//  Created by Sergey Gerashchenko on 4/4/18.
//  Copyright © 2018 Sergey Gerashchenko. All rights reserved.
//

import UIKit

class RepositoryCell: UITableViewCell {
  @IBOutlet weak var repositoryNameLabel: UILabel!
  @IBOutlet weak var starsAmountLabel: UILabel!
  
  func setData(data: RepositoryData) {
    guard let stars = data.starsAmount as? Int,
          let name = data.name
    else { return }
    
    repositoryNameLabel.text = name
    starsAmountLabel.text = String(stars)
  }

}
