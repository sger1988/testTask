//
//  FavoriteRepositoryEntity.swift
//  GitHubReposTask
//
//  Created by Sergey Gerashchenko on 4/6/18.
//  Copyright © 2018 Sergey Gerashchenko. All rights reserved.
//

import Foundation
import CoreData

class FavoriteRepositoryEntity: NSManagedObject, RepositoryData {
  
  @NSManaged var githubId: NSNumber?
  @NSManaged var name: String?
  @NSManaged var starsAmount: NSNumber?
  @NSManaged var repositoryDescription: String?
  @NSManaged var language: String?
  @NSManaged var fullName: String?
  
}
