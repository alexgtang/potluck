////
////  ViewController.swift
////  Recipe App
////
////  Created by Amelie Scheil on 11/6/24.
////
//
//import UIKit
//
//class ViewController: UIViewController {
//
//    var breakfastRecipes: [Recipe] = []
//    var lunchRecipes: [Recipe] = []
//    var dinnerRecipes: [Recipe] = []
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        collectRecipes()
//    }
//    
//    func collectRecipes() {
//        let group = DispatchGroup()
//        
//        group.enter()
//        getRecipes(for: "Breakfast", times: 1) { recipes in
//            self.breakfastRecipes = recipes
//            group.leave()
//        }
//        
//        group.enter()
//        getRecipes(for: "Lunch", times: 1) { recipes in
//            self.lunchRecipes = recipes
//            group.leave()
//        }
//        
//        group.enter()
//        getRecipes(for: "Dinner", times: 1) { recipes in
//            self.dinnerRecipes = recipes
//            group.leave()
//        }
//        
//        group.notify(queue: .main) {
//            print("All recipes collected")
//            //print("Breakfast Recipes: \(self.breakfastRecipes.count)")
//            //print("Lunch Recipes: \(self.lunchRecipes.count)")
//            //print("Dinner Recipes: \(self.dinnerRecipes.count)")
//            if let firstBreakfastRecipe = self.breakfastRecipes.first {
//                    print("First Breakfast Recipe:")
//                    print("Label: \(firstBreakfastRecipe.label)")
//                    print("Calories: \(firstBreakfastRecipe.calories)")
//                } else {
//                    print("No breakfast recipes found.")
//                }
//
//                if let firstLunchRecipe = self.lunchRecipes.first {
//                    print("First Lunch Recipe:")
//                    print("Label: \(firstLunchRecipe.label)")
//                    print("Time: \(firstLunchRecipe.totalTime)")
//                } else {
//                    print("No lunch recipes found.")
//                }
//
//                if let firstDinnerRecipe = self.dinnerRecipes.first {
//                    print("First Dinner Recipe:")
//                    print("Label: \(firstDinnerRecipe.label)")
//                    print("Cautions: \(firstDinnerRecipe.cautions)")
//                } else {
//                    print("No dinner recipes found.")
//                }
//            
//            //Pass each recipe array to GPT afterwards
//        }
//    }
//    
//    func getRecipes(for mealType: String, times: Int, completion: @escaping ([Recipe]) -> Void) {
//        var allRecipes: [Recipe] = []
//        let dispatchGroup = DispatchGroup()
//        
//        for _ in 1...times {
//            dispatchGroup.enter()
//            
//            let urlString = "https://api.edamam.com/api/recipes/v2?type=public&beta=false&app_id=c75ae1c7&app_key=587993214fd6e63640014bbfbc618170&mealType=\(mealType)&random=true&field=label&field=ingredientLines&field=calories&field=url&field=dietLabels&field=healthLabels&field=cautions&field=totalNutrients&field=totalTime"
//            
//            guard let url = URL(string: urlString) else {
//                print("Invalid URL")
//                dispatchGroup.leave()
//                continue
//            }
//            
//            URLSession.shared.dataTask(with: url) { data, response, error in
//                defer { dispatchGroup.leave() }
//                
//                if let error = error {
//                    print("Error fetching recipes: \(error.localizedDescription)")
//                    return
//                }
//                
//                guard let data = data else {
//                    print("Error: No data received")
//                    return
//                }
//                
//                do {
//                    let decoder = JSONDecoder()
//                    decoder.keyDecodingStrategy = .convertFromSnakeCase
//                    let apiResponse = try decoder.decode(RecipeResponse.self, from: data)
//                    
//                    // Append the recipes to allRecipes
//                    let recipes = apiResponse.hits.map { $0.recipe }
//                    allRecipes.append(contentsOf: recipes)
//                } catch {
//                    print("Error decoding data: \(error.localizedDescription)")
//                }
//            }.resume()
//        }
//        
//        dispatchGroup.notify(queue: .main) {
//            // Remove duplicates if necessary
//            let uniqueRecipes = Array(Set(allRecipes))
//            completion(uniqueRecipes)
//        }
//    }
//
//
//
//
//}
//
