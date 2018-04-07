//
//  Constants.swift
//  GitHubReposTask
//
//  Created by Sergey Gerashchenko on 4/5/18.
//  Copyright © 2018 Sergey Gerashchenko. All rights reserved.
//

import Foundation

final class Constants {
  
  struct Segues {
    static let searchDetails   = "SearchDetails"
    static let favoriteDetails = "FavoriteDetails"
  }
  
  struct EntityNames {
    static let tempRepositoryEntity     = "TempRepositoryEntity"
    static let favoriteRepositoryEntity = "FavoriteRepositoryEntity"
  }
  
  struct RepoEntityAttributes {
    static let githubId              = "githubId"
    static let name                  = "name"
    static let starsAmount           = "starsAmount"
    static let repositoryDescription = "repositoryDescription"
    static let language              = "language"
    static let fullName              = "fullName"
    static let order                 = "order"
  }
  
  struct DummyValues {
    static let notDefined: String?   = "Not defined"
    static let dummyNumber: NSNumber = -1
  }
  
  struct EditButtonTitles {
    static let edit = "Edit"
    static let done = "Done"
  }
  
  struct RequestStrings {
    struct URL {
      static let source       = "https://api.github.com/"
      static let users        = "users/"
      static let repositiries = "/repos"
    }
    
    struct Params {
      static let perPage  = "per_page"
      static let page     = "page"
    }
    
    struct Methods {
      static let get    = "GET"
      static let post   = "POST"
      static let put    = "PUT"
      static let delete = "DELETE"
    }
  }
  
  struct Messages {
    static let errorTitle       = "Error"
    static let ok               = "Ok"
    static let noRecords        = "No records for user"
    static let erorrResponse    = "Error processing request"
    static let invalidUsername  = "Entered username is invalid, try another"
    static let modelLoadError   = "Error loading model from bundle"
    static let errorMomInit     = "Error initializing mom from: "
    static let errorDocumentDir = "Unable to resolve document directory"
    static let errorMigrating   = "Error migrating store: "
    static let unresolvedError  = "Unresolved error "
  }
  
  static let searchBarPlaceholder = "Enter user name"
  static let modelName            = "UserRepositoryModel"
  static let pageSize             = 10
  static let usernameRegex        = "^[a-z\\d](?:[a-z\\d]|-(?=[a-z\\d])){0,38}$"
  
}
