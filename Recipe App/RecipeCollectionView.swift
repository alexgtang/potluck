//
//  RecipeCollectionView.swift
//  Recipe App
//
//  Created by Vasilisa Ioukhnovets on 11/22/24.
//

import UIKit

protocol RecipeCollectionViewDelegate: AnyObject {
    func didSelectRecipe(_ recipe: RecipeCard)
}

class RecipeCollectionView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var collectionView: UICollectionView!
    
    weak var delegate: RecipeCollectionViewDelegate?

    private var recipes: [RecipeCard] = []

    // This function is used to configure the collection view with the recipes
    func configure(with recipes: [RecipeCard]) {
        self.recipes = recipes
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.reloadData()
    }

    //UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recipes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecipeCell.reuseIdentifier, for: indexPath) as! RecipeCell
        let recipe = recipes[indexPath.item]
        cell.configure(with: recipe)
        return cell
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedRecipe = recipes[indexPath.item]
        delegate?.didSelectRecipe(selectedRecipe)
    }
}

