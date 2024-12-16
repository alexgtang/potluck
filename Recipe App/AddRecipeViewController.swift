//
//  AddRecipeViewController.swift
//  Recipe App
//
//  Created by Alex Tang on 11/25/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

protocol AddRecipeDelegate: AnyObject {
    func didAddRecipe()
}

class AddRecipeViewController: UIViewController {
    weak var delegate: AddRecipeDelegate?
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Recipe Title"
        tf.borderStyle = .roundedRect
        return tf
    }()
    
    private let timeTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Estimated Time (minutes)"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numberPad
        return tf
    }()
    
    private let ingredientsTextView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.font = .systemFont(ofSize: 16)
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.layer.borderWidth = 1
        tv.layer.cornerRadius = 8
        tv.text = "Ingredients (one per line)"
        tv.textColor = .systemGray
        return tv
    }()
    
    private let instructionsTextView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.font = .systemFont(ofSize: 16)
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.layer.borderWidth = 1
        tv.layer.cornerRadius = 8
        tv.text = "Instructions"
        tv.textColor = .systemGray
        return tv
    }()
    
    private let imageButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Add Image", for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 8
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        return button
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray6
        iv.layer.cornerRadius = 8
        return iv
    }()
    
    private var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupImagePicker()
    }
    
    private func setupNavigationBar() {
        title = "Add Recipe"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        guard let title = titleTextField.text, !title.isEmpty,
              let userId = Auth.auth().currentUser?.uid,
              let userName = Auth.auth().currentUser?.displayName else {
            showAlert(message: "Please fill in all fields")
            return
        }
        
        let loadingAlert = UIAlertController(title: nil, message: "Saving recipe...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        present(loadingAlert, animated: true)
        
        if let image = selectedImage {
            // Generate a unique name for the image
            let imageName = UUID().uuidString
            
            // Save image locally first
            if let localPath = saveImageLocally(image, withName: imageName) {
                // Then upload to Firebase
                uploadImage(image) { [weak self] imageUrl in
                    guard let self = self else { return }
                    self.saveRecipe(
                        title: title,
                        userId: userId,
                        userName: userName,
                        imageUrl: imageUrl,
                        localImagePath: localPath,
                        imageName: imageName,
                        loadingAlert: loadingAlert
                    )
                }
            } else {
                loadingAlert.dismiss(animated: true)
                showAlert(message: "Failed to save image locally")
            }
        } else {
            saveRecipe(
                title: title,
                userId: userId,
                userName: userName,
                imageUrl: nil,
                localImagePath: nil,
                imageName: nil,
                loadingAlert: loadingAlert
            )
        }
    }

    private func saveRecipe(
        title: String,
        userId: String,
        userName: String,
        imageUrl: String?,
        localImagePath: String?,
        imageName: String?,
        loadingAlert: UIAlertController
    ) {
        let db = Firestore.firestore()
        let recipeRef = db.collection("users").document(userId).collection("recipes").document()
        
        var newRecipe: [String: Any] = [
            "id": recipeRef.documentID,
            "title": title,
            "imageUrl": imageUrl ?? "",
            "ingredients": ingredientsTextView.text ?? "",
            "instructions": instructionsTextView.text ?? "",
            "estimatedTime": Int(timeTextField.text ?? "0") ?? 0,
            "authorId": userId,
            "authorName": userName,
            "timestamp": Date().timeIntervalSince1970,
            "type": "uploaded"
        ]
        
        if let imageName = imageName {
            newRecipe["localImageName"] = imageName
        }
        
        recipeRef.setData(newRecipe) { [weak self] error in
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true)
                
                if let error = error {
                    self?.showAlert(message: "Error saving recipe: \(error.localizedDescription)")
                } else {
                    self?.delegate?.didAddRecipe()
                    self?.dismiss(animated: true)
                }
            }
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [titleTextField, timeTextField, imageButton, imageView, ingredientsTextView, instructionsTextView].forEach { 
            contentView.addSubview($0) 
        }
        
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
            
            titleTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            timeTextField.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 20),
            timeTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            timeTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            imageButton.topAnchor.constraint(equalTo: timeTextField.bottomAnchor, constant: 20),
            imageButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            imageButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            imageButton.heightAnchor.constraint(equalToConstant: 44),
            
            imageView.topAnchor.constraint(equalTo: imageButton.bottomAnchor, constant: 10),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            
            ingredientsTextView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            ingredientsTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            ingredientsTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            ingredientsTextView.heightAnchor.constraint(equalToConstant: 150),
            
            instructionsTextView.topAnchor.constraint(equalTo: ingredientsTextView.bottomAnchor, constant: 20),
            instructionsTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            instructionsTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            instructionsTextView.heightAnchor.constraint(equalToConstant: 150),
            instructionsTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func setupImagePicker() {
        imageButton.addTarget(self, action: #selector(imageButtonTapped), for: .touchUpInside)
    }

    @objc private func imageButtonTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(nil)
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child("recipe_images/\(UUID().uuidString).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                completion(url?.absoluteString)
            }
        }
    }

    // Add these utility functions to handle local image storage
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

    private func getLocalImage(name: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent("\(name).jpg")
        return UIImage(contentsOfFile: fileURL.path)
    }
}

extension UIImage {
    func uploadToFirebaseStorage(completion: @escaping (String?) -> Void) {
        let filename = UUID().uuidString + ".jpg"
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child("recipe_images").child(filename)
        
        guard let imageData = self.jpegData(compressionQuality: 0.5) else {
            print("Could not convert image to data")
            completion(nil)
            return
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let uploadTask = imageRef.putData(imageData, metadata: metadata) { (metadata, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            imageRef.downloadURL { (url, error) in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                if let downloadURL = url?.absoluteString {
                    print("Successfully uploaded image. URL: \(downloadURL)")
                    completion(downloadURL)
                } else {
                    completion(nil)
                }
            }
        }
        
        uploadTask.observe(.progress) { snapshot in
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                / Double(snapshot.progress!.totalUnitCount)
            print("Upload is \(percentComplete)% complete")
        }
    }
}

extension AddRecipeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            imageView.image = image
            imageButton.setTitle("Change Image", for: .normal)
        }
        dismiss(animated: true)
    }
}
