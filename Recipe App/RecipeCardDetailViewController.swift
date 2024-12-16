//
//  RecipeDetailViewController.swift
//  Recipe App
//
//  Created by Vasilisa Ioukhnovets on 11/22/24.
//

import UIKit

class RecipeCardDetailViewController: UIViewController {
    
    var recipe: RecipeCard?
    
    @IBOutlet weak var recipeName: UILabel!
    @IBOutlet weak var recipePicture: UIImageView!
    @IBOutlet weak var recipeDescription: UITextView!
    @IBOutlet weak var recipeInstructions: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let recipe = recipe {
            recipePicture.image = (UIImage(named: recipe.imageURL))
            recipeName.text = recipe.title
            //recipeInstructions.text = recipe.description
            // Add more details (ingredients, instructions) here
        }
    }
}
