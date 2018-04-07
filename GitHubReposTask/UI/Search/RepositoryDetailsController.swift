//
//  FavoritesController.swift
//  GitHubReposTask
//
//  Created by Sergey Gerashchenko on 4/5/18.
//  Copyright © 2018 Sergey Gerashchenko. All rights reserved.
//

import UIKit

class RepositoryDetailsController: UIViewController {
  
  @IBOutlet weak var starAmountLabel: UILabel!
  @IBOutlet weak var repositoryNameLabel: UILabel!
  @IBOutlet weak var languageLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var addButton: UIButton!
  @IBOutlet weak var scrollContentView: UIView!
  
  var data: RepositoryData?
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    setData()
    configureButtons()
  }
  
  private func setData() {
    guard let name = data?.name,
          let language = data?.language,
          let description = data?.repositoryDescription,
          let starsAmount = data?.starsAmount as? Int
    else { return }
   
    repositoryNameLabel.text = name
    languageLabel.text = language
    descriptionLabel.text = description
    starAmountLabel.text = String(starsAmount)
  }
  
  private func configureButtons() {
    guard let githubId = data?.githubId else { return }
    
    if data is TempRepositoryEntity && Storage.shared.isAlreadySaved(loadedId: githubId) {
      addButton.isEnabled = false
    } else {
      addButton.isEnabled = true
    }
    
    if data is FavoriteRepositoryEntity {
      addButton.isHidden = true
    }
  }
  
  @IBAction func addToFavorites(_ sender: Any) {
    guard let newFavoriteRepository = data else { return }
    
    Storage.shared.addToFavorites(newFavoriteRepository as! TempRepositoryEntity)
    addButton.isEnabled = false
  }
  
}
