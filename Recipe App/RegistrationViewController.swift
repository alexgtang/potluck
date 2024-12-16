//
//  RegistrationViewController.swift
//  Recipe App
//
//  Created by allison cui on 11/14/24.
//

import UIKit
import FirebaseAuth
import FirebaseAnalytics

// UITextField extension to disable AutoFill
extension UITextField {
    func disableAutoFill() {
        if #available(iOS 12, *) {
            // Disable AutoFill for password fields in iOS 12+
            textContentType = .oneTimeCode
        } else {
            // For earlier versions, set it to an empty string
            textContentType = .init(rawValue: "")
        }
    }
}

class RegistrationViewController: UIViewController {

    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Disable AutoFill
        passwordTextField.disableAutoFill()
        confirmPasswordTextField.disableAutoFill()
    }
    
    @IBAction func goBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)

    }
    @IBAction func submitRegistration(_ sender: Any) {
        let name = nameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let confirmPassword = confirmPasswordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate inputs
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            showAlert(message: "Please fill out all fields.")
            return
        }

        guard password == confirmPassword else {
            showAlert(message: "Passwords do not match.")
            return
        }
        
        // Firebase Registration
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                self.showAlert(message: error.localizedDescription)
            } else {
                if let user = Auth.auth().currentUser {
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = name
                    changeRequest.commitChanges { (error) in
                        if let error = error {
                            self.showAlert(message: "Error updating user profile: \(error.localizedDescription)")
                        } else {
                            Analytics.logEvent("registration_success", parameters: ["email": email])
                            self.showAlert(message: "Registration successful! Return to sign-in page to login") {
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "Message", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true, completion: nil)
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
