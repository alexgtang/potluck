//
//  RecipeDetailViewController.swift
//  Recipe App
//
//  Created by Amelie Scheil on 11/24/24.
//

import UIKit
import WebKit
import FirebaseFirestore
import FirebaseAuth

class RecipeDetailViewController: UIViewController {
    
    var recipe: Recipe?

    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var scheduleButton: UIButton!
    @IBOutlet weak var webView: WKWebView!

    @IBAction func favoriteButtonTapped(_ sender: UIButton) {
        guard let recipe = recipe,
              let userId = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "Please sign in to save favorites")
            return
        }
        
        let db = Firestore.firestore()
        let recipeData: [String: Any] = [
            "title": recipe.label,
            "url": recipe.url,
            "type": "favorite"
        ]
        
        let documentId = recipe.url.replacingOccurrences(of: "/", with: "_")
        
        db.collection("users").document(userId)
            .collection("recipes")
            .document(documentId)
            .getDocument { [weak self] document, error in
                if let document = document, document.exists {
                    // Recipe is already favorited, so remove it
                    document.reference.delete { error in
                        if let error = error {
                            self?.showAlert(title: "Error", message: "Failed to remove favorite: \(error.localizedDescription)")
                        } else {
                            self?.favoriteButton.setTitle("Favorite", for: .normal)
                            self?.favoriteButton.tintColor = .systemGray
                            self?.showAlert(title: "Success", message: "Recipe removed from favorites")
                        }
                    }
                } else {
                    // Recipe is not favorited, so add it
                    db.collection("users").document(userId)
                        .collection("recipes")
                        .document(documentId)
                        .setData(recipeData) { error in
                            if let error = error {
                                self?.showAlert(title: "Error", message: "Failed to save favorite: \(error.localizedDescription)")
                            } else {
                                self?.favoriteButton.setTitle("Favorited", for: .normal)
                                self?.favoriteButton.tintColor = .systemRed
                                self?.showAlert(title: "Success", message: "Recipe added to favorites")
                            }
                        }
                }
        }
    }
    
    @IBAction func scheduleButtonTapped(_ sender: UIButton) {
        guard recipe != nil else {
            showAlert(title: "Error", message: "No recipe data available.")
            return
        }
        performSegue(withIdentifier: "toScheduleRecipe", sender: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadRecipeWebPage()
    }

    private func loadRecipeWebPage() {
        guard let urlString = recipe?.url,
              let url = URL(string: urlString),
              UIApplication.shared.canOpenURL(url) else {
            showAlert(title: "Error", message: "Invalid recipe URL")
            return
        }
        webView.load(URLRequest(url: url))
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toScheduleRecipe" {
            guard let calendarVC = segue.destination as? CalendarViewController else {
                print("Error: Destination is not CalendarViewController")
                return
            }
            guard let recipe = recipe else {
                print("Error: No recipe to pass")
                return
            }
            calendarVC.selectedRecipe = recipe
            print("Passing recipe: \(recipe.label) to CalendarViewController")
        }
    }
}
