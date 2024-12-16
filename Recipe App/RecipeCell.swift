//
//  RecipeCell.swift
//  Recipe App
//
//  Created by Vasilisa Ioukhnovets on 11/22/24.
//

import UIKit

class RecipeCell: UICollectionViewCell {
    static let reuseIdentifier = "RecipeCell"

        // Create the UI elements to display the recipe info
    @IBOutlet weak var recipePicture: UIImageView!
    @IBOutlet weak var recipeName: UILabel!

        // Configure the cell with a recipe
        func configure(with recipe: RecipeCard) {
            recipeName.text = recipe.title
            recipePicture.image = UIImage(named: recipe.imageURL)  // Assuming local images for simplicity
        }
}
