//
//  EdamamRecipe.swift
//  Recipe App
//
//  Created by Amelie Scheil on 11/25/24.
//

import Foundation

struct RecipeSearchResponse: Codable {
    let from: Int
    let to: Int
    let count: Int
    let hits: [Hit]
    
    struct Hit: Codable {
        let recipe: Recipe
    }
}

struct Recipe: Codable {
    // Basic Information
    let label: String
    let image: String
    let cuisineType: [String]?
    let totalTime: Int
    let url: String
    
    // Ingredient Information
    let ingredientLines: [String]
    let ingredients: [Ingredient]
    
    // Additional Recipe Information
    let instructions: [String]?
    
    // Nutrition and Metadata (if needed in future)
    let calories: Double?
    let mealType: [String]?
    let dishType: [String]?
    let healthLabels: [String]?
}

struct Ingredient: Codable {
    let text: String
    let quantity: Double
    let measure: String?
    let food: String
    let weight: Double
    let foodId: String
}
