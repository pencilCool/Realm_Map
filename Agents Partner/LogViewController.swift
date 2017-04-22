/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import MapKit
import RealmSwift
class LogViewController: UITableViewController {
  
  var specimens = try! Realm().objects(Specimen.self).sorted(byKeyPath: "name", ascending: true)
  var searchResults = try! Realm().objects(Specimen.self)
  
  @IBOutlet weak var segmentedControl: UISegmentedControl!
  
  var searchController: UISearchController!
  
  // MARK: - View Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let searchResultsController = UITableViewController(style: .plain)
    searchResultsController.tableView.delegate = self
    searchResultsController.tableView.dataSource = self
    searchResultsController.tableView.rowHeight = 63
    searchResultsController.tableView.register(LogCell.self, forCellReuseIdentifier: "LogCell")
    
    searchController = UISearchController(searchResultsController: searchResultsController)
    searchController.searchResultsUpdater = self
    searchController.searchBar.sizeToFit()
    searchController.searchBar.tintColor = UIColor.white
    searchController.searchBar.delegate = self
    searchController.searchBar.barTintColor = UIColor(red: 0, green: 104.0/255.0, blue: 55.0/255.0, alpha: 1.0)
    tableView.tableHeaderView?.addSubview(searchController.searchBar)
    
    definesPresentationContext = true
  }
    
    func filterResultsWithSearchString(searchString: String) {
        let predicate = NSPredicate(format: "name BEGINSWITH [c]%@", searchString) // 1
        let scopeIndex = searchController.searchBar.selectedScopeButtonIndex // 2
        let realm = try! Realm()
        
        switch scopeIndex {
        case 0:
            searchResults = realm.objects(Specimen.self).filter(predicate).sorted(byKeyPath: "name", ascending: true) // 3
        case 1:
            searchResults = realm.objects(Specimen.self).filter(predicate).sorted(byKeyPath: "created", ascending: true) // 4
        default:
            searchResults = realm.objects(Specimen.self).filter(predicate) // 5
        }
    }
    
  
  override var preferredStatusBarStyle : UIStatusBarStyle {
    return .lightContent
  }
    
  //MARK: - Actions & Segues
  
  @IBAction func scopeChanged(_ sender: AnyObject) {
    let scopeBar = sender as! UISegmentedControl
    let realm = try! Realm()
    
    switch scopeBar.selectedSegmentIndex {
    case 0:
        specimens = realm.objects(Specimen.self).sorted(byKeyPath: "name", ascending: true)
    case 1:
        specimens = realm.objects(Specimen.self).sorted(byKeyPath: "created", ascending: true)
    default:
        specimens = realm.objects(Specimen.self).sorted(byKeyPath: "name", ascending: true)
    }
    tableView.reloadData()
    
  }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)  {
        if (segue.identifier == "Edit") {
            let controller = segue.destination as! AddNewEntryController
            var selectedSpecimen: Specimen!
            let indexPath = tableView.indexPathForSelectedRow
            
            if searchController.isActive {
                let searchResultsController = searchController.searchResultsController as! UITableViewController
                let indexPathSearch = searchResultsController.tableView.indexPathForSelectedRow
                selectedSpecimen = searchResults[indexPathSearch!.row]
            } else {
                selectedSpecimen = specimens[indexPath!.row]
            }
            controller.specimen = selectedSpecimen
        }
    }
    
    
}

// MARK: - UISearchResultsUpdating
extension LogViewController: UISearchResultsUpdating {
  
  func updateSearchResults(for searchController: UISearchController) {
    let searchString = searchController.searchBar.text!
    filterResultsWithSearchString(searchString: searchString)
    
    let searchResultsController = searchController.searchResultsController as! UITableViewController
    searchResultsController.tableView.reloadData()
  }
  
}

// MARK: - UISearchBarDelegate
extension LogViewController:  UISearchBarDelegate {
  
}

// MARK: - UITableViewDataSource
extension LogViewController {
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return searchController.isActive ? searchResults.count : specimens.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = self.tableView.dequeueReusableCell(withIdentifier: "LogCell") as! LogCell
    
    let specimen = searchController.isActive ? searchResults[indexPath.row] : specimens[indexPath.row]
    
    cell.titleLabel.text = specimen.name
    cell.subtitleLabel.text = specimen.category.name
    
    switch specimen.category.name {
    case "Uncategorized":
        cell.iconImageView.image = UIImage(named: "IconUncategorized")
    case "Reptiles":
        cell.iconImageView.image = UIImage(named: "IconReptile")
    case "Flora":
        cell.iconImageView.image = UIImage(named: "IconFlora")
    case "Birds":
        cell.iconImageView.image = UIImage(named: "IconBird")
    case "Arachnid":
        cell.iconImageView.image = UIImage(named: "IconArachnid")
    case "Mammals":
        cell.iconImageView.image = UIImage(named: "IconMammal")
    default:
        cell.iconImageView.image = UIImage(named: "IconUncategorized")
    }
    return cell

  }
  
}

