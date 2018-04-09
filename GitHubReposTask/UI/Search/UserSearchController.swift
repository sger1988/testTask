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
  private var userName: String = "" {
    didSet {
      shouldRequestMoreData = false
    }
  }
  
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
    guard let searchString = searchBar.text?.lowercased(), searchBar.text != "" else { return }
    guard userNameValid(searchString) else { showSimpleAlert(text: Constants.Messages.invalidUserName); return }
    userName = searchString
    
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    
    Storage.shared.fetchData(for: userName) { moreDataAvailable, rowsFetched, error in
      self.shouldRequestMoreData = moreDataAvailable
      
      if let fetchError = error as? Error {
        self.showSimpleAlert(text: fetchError.localizedDescription)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        return
      } else if let message = error as? String {
        self.showSimpleAlert(text: message)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        return
      }
      
      if rowsFetched > 0 {
        self.userSearchTable.reloadData()
      }
      
      UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
  }
  
  private func userNameValid(_ userName: String) -> Bool {
    let usernameRegex = Constants.userNameRegex
    let predicate = NSPredicate(format:"SELF MATCHES %@", usernameRegex)
    return predicate.evaluate(with: userName)
  }
  
  private func showSimpleAlert(text: String) {
    let errorAlert = UIAlertController(title: Constants.Messages.errorTitle, message: text, preferredStyle: UIAlertControllerStyle.alert)
    let okAction = UIAlertAction(title: Constants.Messages.ok, style: .default, handler: nil)
    errorAlert.addAction(okAction)
    
    self.present(errorAlert, animated: true, completion: nil)
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
    userName = ""
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
