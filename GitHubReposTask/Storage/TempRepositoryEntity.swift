//
//  TempRepositoryEntity
//  GitHubReposTask
//
//  Created by Sergey Gerashchenko on 4/5/18.
//  Copyright © 2018 Sergey Gerashchenko. All rights reserved.
//

import Foundation
import CoreData

class TempRepositoryEntity: NSManagedObject, RepositoryData {
  
  @NSManaged var order: NSNumber?
  @NSManaged var githubId: NSNumber?
  @NSManaged var name: String?
  @NSManaged var starsAmount: NSNumber?
  @NSManaged var repositoryDescription: String?
  @NSManaged var language: String?
  @NSManaged var fullName: String?
  
}
