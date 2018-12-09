//
//  ViewController.swift
//  SuryaSoftDemo
//
//  Created by SUBAHAN on 07/12/18.
//  Copyright © 2018 SUBAHAN. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController,UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var emailD : String?
    
    //To Fetch Data From CoreData
    lazy var fetchedhResultController: NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "firstName", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "SuryaSoft"
        tableView.tableFooterView = UIView.init(frame: .zero)
        tableView.estimatedRowHeight = 190
        tableView.rowHeight = UITableView.automaticDimension

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTableContent()
    }
    
    //To Perform Fetch and To Call Api Service
    func updateTableContent() {
        
        do {
            try self.fetchedhResultController.performFetch()
//            print("COUNT FETCHED FIRST: \(String(describing: self.fetchedhResultController.sections?[0].numberOfObjects))")
        } catch let error  {
            print("ERROR: \(error)")
        }
        let sv = UIViewController.displaySpinner(onView: self.view)

        let service = APIService()
        service.getDataWith(email : emailD ?? "") { (result) in
            switch result {
            case .Success(let data):
                self.clearData()
//                print("test",data)
                self.saveInCoreDataWith(array: data)
                UIViewController.removeSpinner(spinner: sv)

            case .Error(let message):
                DispatchQueue.main.async {
                    UIViewController.removeSpinner(spinner: sv)
                    self.showAlertWith(title: "Error", message: message)
                }
            }
        }
    }
    
    //show Message
    func showAlertWith(title: String, message: String, style: UIAlertController.Style = .alert) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        let action = UIAlertAction(title: title, style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func enterEmailId(){
                let alertController = UIAlertController(title: "Enter MailId", message: "", preferredStyle: UIAlertController.Style.alert)
        
                let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler: { alert -> Void in
                    let eventNameTextField = alertController.textFields![0] as UITextField
                    self.emailD = eventNameTextField.text!
                    print(eventNameTextField.text!)
                    self.updateTableContent()
                })
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
                    (action : UIAlertAction!) -> Void in })
                alertController.addTextField { (textField : UITextField!) -> Void in
                    textField.placeholder = "Email Id"
                }
        
                alertController.addAction(saveAction)
                alertController.addAction(cancelAction)
        
                self.present(alertController, animated: true, completion: nil)
    }

    
    
    @IBAction func reEnterMail(_ sender: UIBarButtonItem) {

        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
        
        enterEmailId()

    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = fetchedhResultController.sections?.first?.numberOfObjects {
            return count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let userCell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? UserListTableViewCell
        if let user = fetchedhResultController.object(at: indexPath) as? User {
            userCell?.setPhotoCellWith(user: user)
        }
        
        return userCell!
    }
    
 
// Create CoreData Model Entity
    private func createUserEntityFrom(dictionary: [String: AnyObject]) -> NSManagedObject? {
        
        let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
        if let userEntity = NSEntityDescription.insertNewObject(forEntityName: "User", into: context) as? User {
            userEntity.firstName = dictionary["firstName"] as? String
            userEntity.lastName = dictionary["lastName"] as? String
            userEntity.emailId = dictionary["emailId"] as? String
            userEntity.imageUrl = dictionary["imageUrl"] as? String
            return userEntity
        }
        return nil
    }
    
    // Save Data in CoreData
    private func saveInCoreDataWith(array: [[String: AnyObject]]) {

        _ = array.map{self.createUserEntityFrom(dictionary: $0)}
        do {
            try CoreDataStack.sharedInstance.persistentContainer.viewContext.save()
        } catch let error {
            print(error)
        }
    }
    
    //Delete Data From CoreData
    private func clearData() {
        do {
            
            let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: User.self))
            do {
                let objects  = try context.fetch(fetchRequest) as? [NSManagedObject]
                _ = objects.map{$0.map{context.delete($0)}}
                CoreDataStack.sharedInstance.saveContext()
            } catch let error {
                print("ERROR DELETING : \(error)")
            }
        }
    }


}

class UserListTableViewCell : UITableViewCell{
    @IBOutlet weak var contentContainer: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentContainer.layer.borderColor = UIColor.black.cgColor
        contentContainer.layer.borderWidth = 1
    }
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userEmailIdLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!

    // Set Data into Cell 
    func setPhotoCellWith(user: User) {
        
        DispatchQueue.main.async {
           
            self.userNameLabel.text = (user.firstName ?? "") + (user.lastName ?? "")
            self.userEmailIdLabel.text = (user.emailId ?? "")
            if let url = user.imageUrl {
                self.userImageView.loadImageUsingCacheWithURLString(url, placeHolder: UIImage(named: "placeholder"))
            }
        }
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            self.tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            self.tableView.deleteRows(at: [indexPath!], with: .automatic)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
}
