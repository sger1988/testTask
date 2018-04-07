//
//  Storage.swift
//  GitHubReposTask
//
//  Created by Sergey Gerashchenko on 4/4/18.
//  Copyright © 2018 Sergey Gerashchenko. All rights reserved.
//

import Foundation
import CoreData

protocol RepositoryData {
  var githubId: NSNumber?            { get set }
  var name: String?                  { get set }
  var starsAmount: NSNumber?         { get set }
  var repositoryDescription: String? { get set }
  var language: String?              { get set }
  var fullName: String?              { get set }
}

final class Storage {
  
  struct SerializationKeys {
    static let id               = "id"
    static let name             = "name"
    static let stargazers_count = "stargazers_count"
    static let fullName         = "full_name"
    static let language         = "language"
    static let description      = "description"
  }
  
  static let shared = Storage()
  
  private var mainContext: NSManagedObjectContext
  private var temporaryDataContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
  private var backgroundContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
  
  var tempResultsController: NSFetchedResultsController<TempRepositoryEntity>?
  var favoritesResultsController: NSFetchedResultsController<FavoriteRepositoryEntity>?
  private var page: Int = 1
  
  private init() {
    guard let modelURL = Bundle.main.url(forResource: Constants.modelName, withExtension:"momd") else {
      fatalError(Constants.Messages.modelLoadError)
    }
    guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
      fatalError(Constants.Messages.errorMomInit + "\(modelURL)")
    }
    
    let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
    
    mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    mainContext.persistentStoreCoordinator = psc
    
    let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
    queue.sync {
      guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
        fatalError(Constants.Messages.errorDocumentDir)
      }
      let storeURL = docURL.appendingPathComponent(Constants.modelName+".sqlite")
      do {
        try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
      } catch {
        fatalError(Constants.Messages.errorMigrating + "\(error)")
      }
    }
    
    configureContexts()
  }
  
  private func configureContexts() {
    backgroundContext.parent = temporaryDataContext
    temporaryDataContext.parent = mainContext
  }
  
  func fetchData(for username: String, completion: @escaping (_ moreDataAvailable: Bool, _ rowsFetched: Int, _ error: Any?) -> Void) {
    GetUserReposRequest.fire(username: username, pageToLoad: page, completion: { data, error in
      if error != nil {
        completion(false, 0, error)
      } else {
        guard let fetchedData = data else { return }
        self.parseData(fetchedData, completion)
      }
    })
  }
  
  private func parseData(_ receivedData: Data, _ completion: @escaping (_ moreDataAvailable: Bool, _ rowsFetched: Int, _ error: Any?) -> Void) {
    do {
      if let serializedResponse = try JSONSerialization.jsonObject(with: receivedData, options: .mutableContainers) as? [[String: Any]] {
        backgroundContext.perform {
          for item in serializedResponse {
            if let repositoryName = item[SerializationKeys.name] as? String,
              let starsAmount     = item[SerializationKeys.stargazers_count] as? NSNumber,
              let fullName        = item[SerializationKeys.fullName] as? String,
              let description     = item[SerializationKeys.description] as? String ?? Constants.DummyValues.notDefined,
              let language        = item[SerializationKeys.language] as? String ?? Constants.DummyValues.notDefined,
              let githubId        = item[SerializationKeys.id] as? NSNumber {

              let newRepoDesc = NSEntityDescription.entity(forEntityName: Constants.EntityNames.tempRepositoryEntity, in: self.backgroundContext)
              let repo = NSManagedObject.init(entity: newRepoDesc!, insertInto: self.backgroundContext) as! TempRepositoryEntity
              
              self.setRepoEntityAttributes(entity: repo, githubId, repositoryName, starsAmount, description, language, fullName)
              repo.setValue(Sequence.shared.generateValue(), forKey: Constants.RepoEntityAttributes.order)
            }
          }
          
          self.saveBackgroundContext()
          self.updateLocalData()
          
          if serializedResponse.count == 0 && self.page == 1 {
            DispatchQueue.main.sync {
              completion(false, serializedResponse.count, Constants.Messages.noRecords)
            }
          }
          
          if serializedResponse.count < Constants.pageSize {
            DispatchQueue.main.sync {
              completion(false, serializedResponse.count, nil)
            }
            
          }
          
          if serializedResponse.count > 0 {
            self.prepareTempDatasource()
            DispatchQueue.main.sync {
              completion(true, serializedResponse.count, nil)
            }
          }
          self.page += 1
        }
      }
    } catch let error as NSError? {
      fatalError(Constants.Messages.unresolvedError + "\(String(describing: error)), \(String(describing: error?.userInfo))")
    }
  }
  
  private func updateLocalData() {
    mainContext.performAndWait {
      prepareFavoritesDatasource()
    }
    
    temporaryDataContext.performAndWait {
      prepareTempDatasource()
    }
    
    temporaryDataContext.performAndWait {
      guard let tempResults = tempResultsController?.fetchedObjects else { return }
      
      for item in tempResults where isAlreadySaved(loadedId: item.githubId ?? Constants.DummyValues.dummyNumber) {
        guard let githubId = item.githubId,
          let name = item.name,
          let starsAmount = item.starsAmount,
          let repositoryDescription = item.repositoryDescription,
          let language = item.language,
          let fullName = item.fullName
        else { continue }
        
        mainContext.performAndWait {
          guard let entityForUpdate = favoritesResultsController?.fetchedObjects?.first(where: {$0.githubId == item.githubId && $0.fullName == item.fullName}) else { return }
          setRepoEntityAttributes(entity: entityForUpdate, githubId, name, starsAmount, repositoryDescription, language, fullName)
        }
      }
      mainContext.performAndWait {
        saveMainContext()
      }
    }
    
  }
  
  private func prepareTempDatasource() {
    let request = NSFetchRequest<TempRepositoryEntity>.init(entityName: Constants.EntityNames.tempRepositoryEntity)
    
    request.sortDescriptors = [NSSortDescriptor(key: #keyPath(TempRepositoryEntity.order), ascending: true)]
    tempResultsController = NSFetchedResultsController<TempRepositoryEntity>.init(fetchRequest: request, managedObjectContext: temporaryDataContext, sectionNameKeyPath: nil, cacheName: nil)
    
    do {
      try tempResultsController?.performFetch()
    } catch let error as NSError? {
      fatalError(Constants.Messages.unresolvedError + "\(String(describing: error)), \(String(describing: error?.userInfo))")
    }
  }
  
  func prepareFavoritesDatasource() {
    let request = NSFetchRequest<FavoriteRepositoryEntity>.init(entityName: Constants.EntityNames.favoriteRepositoryEntity)
    
    request.sortDescriptors = [NSSortDescriptor(key: #keyPath(FavoriteRepositoryEntity.fullName), ascending: true)]
    favoritesResultsController = NSFetchedResultsController<FavoriteRepositoryEntity>.init(fetchRequest: request, managedObjectContext: mainContext, sectionNameKeyPath: nil, cacheName: nil)
    
    do {
      try favoritesResultsController?.performFetch()
    } catch let error as NSError? {
      fatalError(Constants.Messages.unresolvedError + "\(String(describing: error)), \(String(describing: error?.userInfo))")
    }
  }
  
  private func saveMainContext() {
    if mainContext.hasChanges {
      do {
        try mainContext.save()
      } catch let error as NSError? {
        fatalError(Constants.Messages.unresolvedError + "\(String(describing: error)), \(String(describing: error?.userInfo))")
      }
    }
  }
  
  private func saveBackgroundContext() {
    if backgroundContext.hasChanges {
      do {
        try self.backgroundContext.save()
      } catch let error as NSError? {
        fatalError(Constants.Messages.unresolvedError + "\(String(describing: error)), \(String(describing: error?.userInfo))")
      }
    }
  }
  
  private func setRepoEntityAttributes<repoEntity: NSManagedObject>(entity: repoEntity, _ id: NSNumber, _ name: String,_ starsAmount: NSNumber, _ repositoryDescription: String, _ language: String, _ fullName: String) {
    entity.setValue(id, forKey: Constants.RepoEntityAttributes.githubId)
    entity.setValue(name, forKey: Constants.RepoEntityAttributes.name)
    entity.setValue(starsAmount, forKey: Constants.RepoEntityAttributes.starsAmount)
    entity.setValue(repositoryDescription, forKey: Constants.RepoEntityAttributes.repositoryDescription)
    entity.setValue(language, forKey: Constants.RepoEntityAttributes.language)
    entity.setValue(fullName, forKey: Constants.RepoEntityAttributes.fullName)
  }
  
  func addToFavorites(_ data: TempRepositoryEntity) {
    let favoriteRepoEntityDesc = NSEntityDescription.entity(forEntityName: Constants.EntityNames.favoriteRepositoryEntity, in: mainContext)
    let newFavorityRepo = NSManagedObject.init(entity: favoriteRepoEntityDesc!, insertInto: mainContext)
    
    guard let name = data.name,
          let language = data.language,
          let description = data.repositoryDescription,
          let starsAmount = data.starsAmount,
          let fullName = data.fullName,
          let githubId = data.githubId
    else { return }
    
    setRepoEntityAttributes(entity: newFavorityRepo, githubId, name, starsAmount, description, language, fullName)
    saveMainContext()
  }
  
  func removeFromFavorites(_ data: FavoriteRepositoryEntity) {
    mainContext.delete(data)
    prepareFavoritesDatasource()
    saveMainContext()
  }
  
  func isAlreadySaved(loadedId: NSNumber) -> Bool {
    prepareFavoritesDatasource()
    let result = favoritesResultsController?.fetchedObjects?.contains { $0.githubId == loadedId }
    
    return result ?? false
  }
  
  func clearTempContext() {
    page = 1
    temporaryDataContext.reset()
    prepareTempDatasource()
  }
  
}
