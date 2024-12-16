//
//  FirebaseViewController.swift
//  Recipe App
//
//  Created by Ariel Thongkham on 11/13/24.
//

import UIKit
import FirebaseAuth
import FirebaseAnalytics
import FirebaseFirestore

class FirebaseViewController: UIViewController {

    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBAction func registerBtn(_ sender: Any) {
        performSegue(withIdentifier: "goToRegistration", sender: self)
    }
    
    @IBAction func loginBtn(_ sender: Any) {
        print("Start cooking")
        
        let email = email.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = password.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // User Login
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if error != nil {
                let alert = UIAlertController(title: "Error", message: "\(error!.localizedDescription)",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                self.present(alert, animated: true)
            } else {
                Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                    AnalyticsParameterItemID: "id-login",
                    AnalyticsParameterItemName: email,
                    AnalyticsParameterContentType: "cont",
                ])

                // Check and add user to Firestore
                self.handleUserLogin()
                
                self.performSegue(withIdentifier: "homePageSegue", sender: nil)
            }
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func handleUserLogin() {
        if let user = Auth.auth().currentUser {
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(user.uid)
            
            userRef.getDocument { (document, error) in
                if let error = error {
                    print("Error checking user in Firestore: \(error.localizedDescription)")
                    return
                }
                
                if document?.exists == false {
                    // If user not in firestore --> add them
                    userRef.setData([
                        "uid": user.uid,
                        "email": user.email ?? "",
                        "name": user.displayName ?? user.email?.components(separatedBy: "@").first ?? "Anonymous",
                        "friends": [] // Initialize friends list
                    ]) { error in
                        if let error = error {
                            print("Error adding user to Firestore: \(error.localizedDescription)")
                        } else {
                            print("User added to Firestore")
                        }
                    }
                } else {
                    print("User already exists in Firestore")
                }
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
