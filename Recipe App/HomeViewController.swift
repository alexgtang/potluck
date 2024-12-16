//
//  HomeViewController.swift
//  Recipe App
//
//  Created by Vasilisa Ioukhnovets on 11/22/24.
//

import UIKit

class HomeViewController: UIViewController, RecipeCollectionViewDelegate {
    func didSelectRecipe(_ recipe: RecipeCard) {
        performSegue(withIdentifier: "showRecipeDetails", sender: recipe)
    }
    
    
    @IBOutlet weak var recipeCollectionView: RecipeCollectionView!
    
    @IBOutlet weak var discoverRecipeCollectionView: RecipeCollectionView!
    
    //placeholder
    private let dummyRecipes = [
        RecipeCard(title: "Pasta Carbonara", imageURL: "pasta"),
        RecipeCard(title: "Chicken Curry", imageURL: "curry"),
        RecipeCard(title: "Caesar Salad", imageURL: "salad"),
        RecipeCard(title: "Beef Stir Fry", imageURL: "stirfry"),
        RecipeCard(title: "Chocolate Cake", imageURL: "cake")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        recipeCollectionView.delegate = self
        discoverRecipeCollectionView.delegate = self
        
        recipeCollectionView.configure(with: dummyRecipes)
        discoverRecipeCollectionView.configure(with: dummyRecipes)

        configureCollectionViewLayout(for: recipeCollectionView)
        configureCollectionViewLayout(for: discoverRecipeCollectionView)
    
    }
    
    private func configureCollectionViewLayout(for collectionView: RecipeCollectionView) {
        let layout = UICollectionViewFlowLayout()
        
        let screenWidth = UIScreen.main.bounds.width
        let spacing: CGFloat = 5 // Space between cells
        let totalSpacing = spacing * CGFloat(dummyRecipes.count - 1) // Total spacing
        
        layout.itemSize = CGSize(width: 150, height: 150) // Set item size
        layout.minimumInteritemSpacing = spacing // Horizontal spacing
        layout.minimumLineSpacing = spacing // Vertical spacing
        layout.scrollDirection = .horizontal // Horizontal scroll
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) // Padding around the collection view
        
        // Apply the layout to the internal collectionView inside RecipeCollectionView
        collectionView.collectionView.collectionViewLayout = layout
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRecipeDetails",
           let destinationVC = segue.destination as? RecipeCardDetailViewController,
           let selectedRecipe = sender as? RecipeCard {
            destinationVC.recipe = selectedRecipe // Pass the selected recipe data to RecipeDetailViewController
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
    
