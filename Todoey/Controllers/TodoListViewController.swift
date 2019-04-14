//
//  ViewController.swift
//  Todoey
//
//  Created by Xinyi Zhao on 4/1/19.
//  Copyright © 2019 Xinyi Zhao. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework

class TodoListViewController: SwipeTableViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    let realm = try! Realm()
    var todoItems: Results<Item>?
    
    var selectedCategory: Category? {
        didSet {
            loadItems()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.

        
    }

    override func viewWillAppear(_ animated: Bool) {
        
        guard let hexColor = selectedCategory?.hexColor else { fatalError() }
            
        title = selectedCategory!.name
    
        updateNavbar(withHexColor: hexColor)
            
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        updateNavbar(withHexColor: "1D9BF6")
        
    }
    
    func updateNavbar(withHexColor hexColor: String) {
        
        guard let navBar = navigationController?.navigationBar else {
            fatalError("navigation controller does not exist")
        }
        guard let navbarColor = UIColor(hexString: hexColor) else { fatalError() }
        
        searchBar.barTintColor = navbarColor
        
        navBar.barTintColor = navbarColor
        
        navBar.tintColor = ContrastColorOf(navbarColor, returnFlat: true)
        
        navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: ContrastColorOf(navbarColor, returnFlat: true)]
    
    }
    
    
    //MARK - TableView Datasource Methods
    
    
    //how to display the cell in table
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoItemCell", for: indexPath)
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if let item = todoItems?[indexPath.row] {
            // textLabel is the main content of a table cell
            cell.textLabel?.text = item.title
            
            //add a checkmark effect
            cell.accessoryType = item.done ? .checkmark : .none
            
            if let color = UIColor(hexString: selectedCategory!.hexColor)?.darken(byPercentage: CGFloat(indexPath.row) / CGFloat(todoItems!.count)) {
                cell.backgroundColor = color
                cell.textLabel?.textColor = ContrastColorOf(color, returnFlat: true)
            }
            
        }
        else {
            cell.textLabel?.text = "No Item Added..."
        }

        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoItems?.count ?? 1
    }
    
    
    //MARK - Tableview Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //todoItems?[indexPath.row].done = !todoItems?[indexPath.row].done
        if let item = todoItems?[indexPath.row] {
            do {
                try realm.write {
                    //realm.delete(item)
                    item.done = !item.done
                }
            } catch {
                print("Error saving done status: \(error)")
            }
        }
        tableView.reloadData()
        
        //add a flash effect
        tableView.deselectRow(at: indexPath, animated: true)
        
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
            if let currentCategory = self.selectedCategory {
                do {
                    try self.realm.write {
                        let newItem = Item()
                        newItem.title = textField.text!
                        newItem.dateCreated = Date()
                        //the following line, append the newItem must inside a realm write block
                        currentCategory.items.append(newItem)
                        self.realm.add(newItem)
                        self.tableView.reloadData()
                    }
                } catch {
                    print("Error saving data in Realm: \(error)")
                }
            }
            
        }
        
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
        
    }
    
    
    func loadItems() {

        todoItems = selectedCategory?.items.sorted(byKeyPath: "dateCreated", ascending: true)

        tableView.reloadData()
    }
    
    //MARK: - Delete Data from Swipe
    
    override func updateModel(at indexPath: IndexPath) {
        // handle action by updating model with deletion
        //if let categoryToDelete = self.categories?[indexPath.row] {
        if let itemToDelete = self.todoItems?[indexPath.row] {
            
            do {
                try self.realm.write {
                    self.realm.delete(itemToDelete)
                }
            } catch {
                print("Error deleting item")
            }
            
        }
    }

}

//MARK: Search bar methods
//when need to conform to a protocol/become a delegate,
//we should create an extension and group these delegate methods together
//easy to debug and better organized

extension TodoListViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //print(searchBar.text!)  //will print search content
        todoItems = todoItems?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "title", ascending: true)
        tableView.reloadData()

//        //fetch all the items in context
//        let request: NSFetchRequest<Item> = Item.fetchRequest()
//
//        //add a filter
//        request.predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
//
//        //add a sort method
//        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
//
//        loadItems(with: request, predicate: request.predicate)

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

