//
//  ProfileViewController.swift
//  Recipe App
//
//  Created by Alex Tang on 11/16/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct RecipeCard {
    let title: String
    let imageURL: String
}

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {


    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var friendsCountLabel: UILabel!
    @IBOutlet weak var recipeCount: UILabel!
    private var friendsCount: Int = 0
    
    private var uploadedRecipes: [String] = []
    private var generatedRecipes: [String] = []
    private var favoriteRecipes: [String] = []
    private var friendsListener: ListenerRegistration?
    private var recipesListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserData()
        setupUserImage()
        setupTableView()
        setupNavigationBar()
        fetchFriendsCount()
        listenForFriendsUpdates()
        fetchRecipes()
        listenForRecipeUpdates()
        loadProfilePicture()
    }
    
    private func fetchFriendsCount() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching friends: \(error.localizedDescription)")
                return
            }
            
            if let friendIds = document?.data()?["friends"] as? [String] {
                self?.friendsCount = friendIds.count
                DispatchQueue.main.async {
                    self?.friendsCountLabel.text = "\(friendIds.count)"
                }
            }
        }
    }
    
    private func listenForFriendsUpdates() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
            
        friendsListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                if let error = error {
                    print("Error listening for friend updates: \(error.localizedDescription)")
                    return
                }
                    
                guard let data = documentSnapshot?.data(),
                        let friendIds = data["friends"] as? [String] else {
                    return
                }
                    
                self?.friendsCount = friendIds.count
                DispatchQueue.main.async {
                    self?.friendsCountLabel.text = "\(friendIds.count)"
                }
            }
    }
    
    private func loadUserData() {
       if let user = Auth.auth().currentUser,
          let email = user.email,
          let name = user.displayName{
           emailLabel.text = email
           nameLabel.text = "Chef " + name
       }
   }
    
    private func setupUserImage() {
        userImage.backgroundColor = .systemGray5
        userImage.layer.cornerRadius = userImage.frame.width / 2
        userImage.clipsToBounds = true
        userImage.layer.borderWidth = 2
        userImage.layer.borderColor = UIColor.systemGray4.cgColor
        
        let editButton = UIButton(type: .system)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.setImage(UIImage(systemName: "pencil.circle.fill"), for: .normal)
        editButton.tintColor = .systemGray
        editButton.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        editButton.addTarget(self, action: #selector(editProfilePictureTapped), for: .touchUpInside)
        
        view.addSubview(editButton)
        
        NSLayoutConstraint.activate([
            editButton.bottomAnchor.constraint(equalTo: userImage.bottomAnchor, constant: 8),
            editButton.trailingAnchor.constraint(equalTo: userImage.trailingAnchor, constant: 8),
            editButton.widthAnchor.constraint(equalToConstant: 35),
            editButton.heightAnchor.constraint(equalToConstant: 35)
        ])
    }
    
    @objc private func editProfilePictureTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RecipeCell")
        tableView.sectionHeaderTopPadding = 0
    }
    
    private func fetchRecipes() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).collection("recipes").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching recipes: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            var uploaded: [String] = []
            var generatedAndFavorites: [String] = []
            
            for document in documents {
                let data = document.data()
                if let title = data["title"] as? String,
                   let type = data["type"] as? String {
                    if type == "uploaded" {
                        uploaded.append(title)
                    } else if type == "favorite" {
                        generatedAndFavorites.append(title)
                    }
                }
            }
            
            self?.uploadedRecipes = uploaded
            self?.generatedRecipes = generatedAndFavorites
            
            DispatchQueue.main.async {
                self?.recipeCount.text = "\(uploaded.count + generatedAndFavorites.count)"
                self?.tableView.reloadData()
            }
        }
    }
    
    private func listenForRecipeUpdates() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // Listen to real-time updates for any changes in the recipes collection
        recipesListener = db.collection("users").document(userId).collection("recipes")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening for recipe updates: \(error.localizedDescription)")
                    return
                }

                var uploaded: [String] = []
                var generatedAndFavorites: [String] = []

                snapshot?.documents.forEach { document in
                    let data = document.data()
                    if let title = data["title"] as? String,
                        let type = data["type"] as? String {
                        if type == "uploaded" {
                            uploaded.append(title)
                        } else if type == "favorite" {
                            generatedAndFavorites.append(title)
                        }
                    }
                }

                self?.uploadedRecipes = uploaded
                self?.generatedRecipes = generatedAndFavorites

                DispatchQueue.main.async {
                    self?.recipeCount.text = "\(uploaded.count + generatedAndFavorites.count)"
                    self?.tableView.reloadData()
                }
            }
    }
    
    private func setupNavigationBar() {
        let settingsMenu = UIMenu(title: "", children: [
            UIAction(title: "Change Password", image: UIImage(systemName: "key.fill")) { [weak self] action in
                self?.showChangePasswordAlert()
            },
            UIAction(title: "Sign Out", image: UIImage(systemName: "rectangle.portrait.and.arrow.right"),
                    attributes: .destructive) { [weak self] action in
                self?.signOut()
            }
        ])
        
        // Create settings button
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gearshape.fill"),
            menu: settingsMenu
        )
        settingsButton.tintColor = .systemGray
        
        navigationItem.rightBarButtonItem = settingsButton
    }
    
    private func showChangePasswordAlert() {
        let alert = UIAlertController(title: "Change Password",
                                    message: "Enter your new password",
                                    preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "New Password"
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Change", style: .default) { [weak self] _ in
            guard let newPassword = alert.textFields?.first?.text,
                  !newPassword.isEmpty else { return }
            
            self?.updatePassword(newPassword)
        })
        
        present(alert, animated: true)
    }
    
    private func updatePassword(_ newPassword: String) {
        Auth.auth().currentUser?.updatePassword(to: newPassword) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                let alert = UIAlertController(title: "Error",
                                            message: error.localizedDescription,
                                            preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            } else {
                let alert = UIAlertController(title: "Success",
                                            message: "Password updated successfully",
                                            preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
    
    private func signOut() {
        let alert = UIAlertController(title: "Sign Out",
                                    message: "Are you sure you want to sign out?",
                                    preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
            do {
                try Auth.auth().signOut()
                // Navigate to login screen
                if let scene = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
                    scene.window?.rootViewController = loginVC
                }
            } catch {
                let errorAlert = UIAlertController(title: "Error",
                                                 message: "Failed to sign out",
                                                 preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(errorAlert, animated: true)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func uploadProfilePicture(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.5),
              let userId = Auth.auth().currentUser?.uid else { return }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images/\(userId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Save locally first
        if let _ = saveImageLocally(image, withName: "profile_\(userId)") {
            // Then upload to Firebase
            profileImageRef.putData(imageData, metadata: metadata) { [weak self] metadata, error in
                if let error = error {
                    print("Error uploading profile image: \(error.localizedDescription)")
                    return
                }
                
                profileImageRef.downloadURL { [weak self] url, error in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                        return
                    }
                    
                    if let downloadURL = url?.absoluteString {
                        // Save the URL to Firestore
                        let db = Firestore.firestore()
                        db.collection("users").document(userId).setData([
                            "profileImageUrl": downloadURL
                        ], merge: true)
                    }
                }
            }
        }
    }
    
    private func saveImageLocally(_ image: UIImage, withName name: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            return nil
        }
        
        let filename = "\(name).jpg"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving image locally: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func loadProfilePicture() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Try to load local image first
        if let localImage = getLocalImage(name: "profile_\(userId)") {
            userImage.image = localImage
            return
        }
        
        // If no local image, try to load from Firestore
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let imageUrl = document?.data()?["profileImageUrl"] as? String,
               let url = URL(string: imageUrl) {
                URLSession.shared.dataTask(with: url) { data, _, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self?.userImage.image = image
                        }
                    }
                }.resume()
            }
        }
    }
    
    private func getLocalImage(name: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent("\(name).jpg")
        return UIImage(contentsOfFile: fileURL.path)
    }

    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            userImage.image = editedImage
            uploadProfilePicture(editedImage)
        } else if let originalImage = info[.originalImage] as? UIImage {
            userImage.image = originalImage
            uploadProfilePicture(originalImage)
        }
        dismiss(animated: true)
    }
    
    deinit {
        friendsListener?.remove()
        recipesListener?.remove()
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

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return uploadedRecipes.count
        case 1: return generatedRecipes.count + favoriteRecipes.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath)
        
        let recipe: String
        if indexPath.section == 0 {
            recipe = uploadedRecipes[indexPath.row]
        } else {
            let combinedRecipes = generatedRecipes + favoriteRecipes
            recipe = combinedRecipes[indexPath.row]
        }
        
        var config = cell.defaultContentConfiguration()
        config.text = recipe
        cell.contentConfiguration = config
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Uploaded Recipes" : "Favorite Recipes"
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemGray6
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.text = section == 0 ? "Uploaded Recipes" : "Favorite Recipes"
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            // Handle uploaded recipe tap
            let recipeName = uploadedRecipes[indexPath.row]
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            let db = Firestore.firestore()
            db.collection("users").document(userId)
                .collection("recipes")
                .whereField("title", isEqualTo: recipeName)
                .getDocuments { [weak self] snapshot, error in
                    if let document = snapshot?.documents.first {
                        let data = document.data()
                        let recipeDetails = UploadedRecipe(
                            title: data["title"] as? String ?? "",
                            ingredients: data["ingredients"] as? String ?? "",
                            instructions: data["instructions"] as? String ?? "",
                            estimatedTime: data["estimatedTime"] as? Int ?? 0,
                            imageUrl: data["imageUrl"] as? String ?? "",
                            localImageName: data["localImageName"] as? String
                        )
                        
                        DispatchQueue.main.async {
                            self?.showRecipeDetails(recipe: recipeDetails)
                        }
                    }
                }
        } else {
            // Handle favorite/generated recipe tap
            let combinedRecipes = generatedRecipes + favoriteRecipes
            let recipeTitle = combinedRecipes[indexPath.row]
            
            // Fetch the URL for the favorite recipe
            guard let userId = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()
            
            db.collection("users").document(userId)
                .collection("recipes")
                .whereField("title", isEqualTo: recipeTitle)
                .getDocuments { [weak self] snapshot, error in
                    if let document = snapshot?.documents.first,
                       let urlString = document.data()["url"] as? String,
                       let url = URL(string: urlString) {
                        DispatchQueue.main.async {
                            UIApplication.shared.open(url)
                        }
                    }
                }
        }
    }
    
    private func showRecipeDetails(recipe: UploadedRecipe) {
        let detailVC = UploadedRecipeDetailViewController()
        detailVC.recipe = recipe
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

struct UploadedRecipe {
    let title: String
    let ingredients: String
    let instructions: String
    let estimatedTime: Int
    let imageUrl: String
    let localImageName: String?
}

class UploadedRecipeDetailViewController: UIViewController {
    
    var recipe: UploadedRecipe?
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let recipeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        label.textColor = .systemGray
        return label
    }()
    
    private let ingredientsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.text = "Ingredients"
        return label
    }()
    
    private let ingredientsTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 16)
        textView.isEditable = false
        textView.isScrollEnabled = false
        return textView
    }()
    
    private let instructionsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.text = "Instructions"
        return label
    }()
    
    private let instructionsTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 16)
        textView.isEditable = false
        textView.isScrollEnabled = false
        return textView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [recipeImageView, titleLabel, timeLabel, ingredientsLabel, ingredientsTextView,
         instructionsLabel, instructionsTextView].forEach { contentView.addSubview($0) }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            recipeImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            recipeImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            recipeImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            recipeImageView.heightAnchor.constraint(equalTo: recipeImageView.widthAnchor, multiplier: 0.75),
            
            titleLabel.topAnchor.constraint(equalTo: recipeImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            ingredientsLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),
            ingredientsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            ingredientsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            ingredientsTextView.topAnchor.constraint(equalTo: ingredientsLabel.bottomAnchor, constant: 8),
            ingredientsTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            ingredientsTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            
            instructionsLabel.topAnchor.constraint(equalTo: ingredientsTextView.bottomAnchor, constant: 16),
            instructionsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            instructionsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            instructionsTextView.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 8),
            instructionsTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            instructionsTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            instructionsTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func configureUI() {
        guard let recipe = recipe else { return }
        
        titleLabel.text = recipe.title
        timeLabel.text = "\(recipe.estimatedTime) minutes"
        ingredientsTextView.text = recipe.ingredients
        instructionsTextView.text = recipe.instructions
        
        // Try to load local image first
        if let localImageName = recipe.localImageName,
           let localImage = getLocalImage(name: localImageName) {
            recipeImageView.image = localImage
        }
        // If no local image or loading failed, try loading from URL
        else if let imageUrl = URL(string: recipe.imageUrl) {
            URLSession.shared.dataTask(with: imageUrl) { [weak self] data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.recipeImageView.image = image
                    }
                }
            }.resume()
        }
    }
    
    private func getLocalImage(name: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent("\(name).jpg")
        return UIImage(contentsOfFile: fileURL.path)
    }
}

