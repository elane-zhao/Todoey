//
//  ViewController.swift
//  Todoey
//
//  Created by Xinyi Zhao on 4/1/19.
//  Copyright © 2019 Xinyi Zhao. All rights reserved.
//

import UIKit
import CoreData

class TodoListViewController: UITableViewController {

    //var itemArray = ["Find Mike", "Buy Eggoes", "Respond to emails"]
    var itemArray = [Item]()
    
    var selectedCategory: Category? {
        didSet {
            loadItems()
        }
    }
    
    //let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //print(dataFilePath)
        
    }

    //MARK - TableView Datasource Methods
    
    //how to display the cell in table
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoItemCell", for: indexPath)
        let item = itemArray[indexPath.row]
        // textLabel is the main content of a table cell
        cell.textLabel?.text = item.title
        
        //add a checkmark effect
        cell.accessoryType = item.done ? .checkmark : .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }
    
    
    //MARK - Tableview Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print(itemArray[indexPath.row])
        itemArray[indexPath.row].done = !itemArray[indexPath.row].done
        
        //CRUD UPDATE
        //itemArray[indexPath.row].setValue("Completed", forKey: "title")
        
        //CRUD DELETE
        //second line is to remove empty reference cell in itemArray for displaying tableview
        //these 2 lines order matters! otherwise will result in indexOutOfBound Error
//        context.delete(itemArray[indexPath.row])
//        itemArray.remove(at: indexPath.row)
        
        
        saveItems()
        //add a flash effect
        tableView.deselectRow(at: indexPath, animated: true)
        //Force the system to call the table view data source method again! namely tableView cellForRowAt method
//        tableView.reloadData()
        
    }
    
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        //create a textField variable to store the alertTextField data inside the closure
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Todoey Item", message: "", preferredStyle: .alert)
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create a new item..."
            textField = alertTextField
        }
        
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            
            // what will happen once the user clicks the add item button
            
            let item = Item(context: self.context)
            
            item.title = textField.text!
            item.done = false
            //add parent category
            item.parentCategory = self.selectedCategory
            self.itemArray.append(item)
            
            self.saveItems()
            
        }
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
        
        
    }
    
    
    func saveItems() {
        do {
            //Commit changes in context to persistent container
            try context.save()
        }
        catch {
            print("Error saving context: \(error)")
        }
        
        tableView.reloadData()
    }
    
    
    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil) {
        
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory!.name!)
        //request.predicate = categoryPredicate
        
        if let searchPredicate = predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, searchPredicate])
        } else {
            request.predicate = categoryPredicate
        }
        
        do {
            itemArray = try context.fetch(request)
        }
        catch {
            print("Error fetching items from context: \(error)")
        }
        
        tableView.reloadData()
    }

}

//MARK: Search bar methods
//when need to conform to a protocol/become a delegate,
//we should create an extension and group these delegate methods together
//easy to debug and better organized

extension TodoListViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //print(searchBar.text!)  //will print search content
        
        //fetch all the items in context
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        
        //add a filter
        request.predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
        
        //add a sort method
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        loadItems(with: request, predicate: request.predicate)
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
            //when loading items in other background threads
            //try firstly dismiss the searchbar in main thread,
            //dont want to wait for load data to complete
            //not freeze our app
            DispatchQueue.main.async {
                //back to original state, disable keyboard entering and cursor at searchbar
                searchBar.resignFirstResponder()
            }
        
        }
    }
}

