//
//  FavoritesController.swift
//  GitHubReposTask
//
//  Created by Sergey Gerashchenko on 4/6/18.
//  Copyright © 2018 Sergey Gerashchenko. All rights reserved.
//

import UIKit

class FavoritesController: UIViewController {
  @IBOutlet weak var favoritesTable: UITableView!
  @IBOutlet weak var editButton: UIBarButtonItem!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    favoritesTable.dataSource = self
  }
 
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    Storage.shared.prepareFavoritesDatasource()
    favoritesTable.reloadData()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Constants.Segues.favoriteDetails {
      guard let destination = segue.destination as? RepositoryDetailsController,
            let selectedItem = favoritesTable.indexPathForSelectedRow?.row
      else { return }
      
      destination.data = Storage.shared.favoritesResultsController?.fetchedObjects![selectedItem]
    }
  }
  
  @IBAction func tapEdit(_ sender: Any) {
    favoritesTable.setEditing(!favoritesTable.isEditing, animated: true)
    if favoritesTable.isEditing == false {
      editButton.title = Constants.EditButtonTitles.edit
    } else {
      editButton.title = Constants.EditButtonTitles.done
    }
  }
  
}

extension FavoritesController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let dataSource = Storage.shared.favoritesResultsController?.fetchedObjects else { return 0 }
    
    return dataSource.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RepositoryCell.self), for: indexPath) as! RepositoryCell
    
    guard let dataSource = Storage.shared.favoritesResultsController?.fetchedObjects else { return UITableViewCell() }
    cell.setData(data: dataSource[indexPath.row])
    
    return cell
  }
  
}

extension FavoritesController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      guard let deletedRecord = Storage.shared.favoritesResultsController?.fetchedObjects?[indexPath.row] else { return }
      
      Storage.shared.removeFromFavorites(deletedRecord)
      tableView.reloadData()
    }
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
}
