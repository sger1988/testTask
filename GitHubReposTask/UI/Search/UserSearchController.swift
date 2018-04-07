//
//  SearchUserController.swift
//  GitHubReposTask
//
//  Created by Sergey Gerashchenko on 4/4/18.
//  Copyright © 2018 Sergey Gerashchenko. All rights reserved.
//

import UIKit

class UserSearchController: UIViewController {
  
  @IBOutlet weak var userSearchTable: UITableView!
  private var searchBar = UISearchBar()
  private var shouldRequestMoreData = true
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configure()
  }

  private func configure() {
    userSearchTable.keyboardDismissMode = .onDrag
    userSearchTable.dataSource = self
    userSearchTable.delegate = self
    searchBar.placeholder = Constants.searchBarPlaceholder
    searchBar.delegate = self
    searchBar.showsCancelButton = true
    navigationItem.titleView = searchBar
  }
  
  private func requestData() {
    guard let searchString = searchBar.text?.lowercased() else { return }
    
    switch isUserNameValid(searchString) {
    case true:
      break
    case false:
      let validationErrorAlert = UIAlertController(title: nil, message: Constants.Messages.invalidUsername, preferredStyle: .alert)
      let okAction = UIAlertAction(title: Constants.Messages.ok, style: .default, handler: nil)
      validationErrorAlert.addAction(okAction)
      self.present(validationErrorAlert, animated: true, completion: nil)
      
      return
    }
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    Storage.shared.fetchData(for: searchString) { moreDataAvailable, rowsFetched, error in
      
      self.shouldRequestMoreData = moreDataAvailable
      if let fetchError = error as? Error {
        let errorAlert = UIAlertController(title: Constants.Messages.errorTitle, message: fetchError.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: Constants.Messages.ok, style: UIAlertActionStyle.default, handler: nil)
        errorAlert.addAction(okAction)
        
        self.present(errorAlert, animated: true, completion: nil)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        return
      } else if let message = error as? String {
        let errorAlert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: Constants.Messages.ok, style: UIAlertActionStyle.default, handler: nil)
        errorAlert.addAction(okAction)
        
        self.present(errorAlert, animated: true, completion: nil)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        return
      }
      
      if rowsFetched > 0 {
        self.userSearchTable.reloadData()
      }
      
      UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
  }
  
  private func isUserNameValid(_ username: String) -> Bool {
    let usernameRegex = Constants.usernameRegex
    let predicate = NSPredicate(format:"SELF MATCHES %@", usernameRegex)
    return predicate.evaluate(with: username)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Constants.Segues.searchDetails {
      
      self.searchBar.endEditing(true)
      guard let destination = segue.destination as? RepositoryDetailsController,
            let selectedItem = userSearchTable.indexPathForSelectedRow?.row
      else { return }
      
      destination.data = Storage.shared.tempResultsController?.fetchedObjects![selectedItem]
    }
  }
  
}

extension UserSearchController: UISearchBarDelegate {
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    Storage.shared.clearTempContext()
    requestData()
    shouldRequestMoreData = true
    searchBar.endEditing(true)
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
    searchBar.endEditing(true)
    searchBar.text = ""
    shouldRequestMoreData = false
    Storage.shared.clearTempContext()
    userSearchTable.reloadData()
  }
  
}

extension UserSearchController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let dataSource = Storage.shared.tempResultsController?.fetchedObjects else { return 0 }
    
    return dataSource.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RepositoryCell.self), for: indexPath) as! RepositoryCell
    
    guard let dataSource = Storage.shared.tempResultsController?.fetchedObjects else { return UITableViewCell() }
    
    cell.setData(data: dataSource[indexPath.row])
    if indexPath.row == dataSource.count-1 && shouldRequestMoreData {
      requestData()
    }
    
    return cell
  }
  
}

extension UserSearchController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
}
