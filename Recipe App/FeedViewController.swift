//
//  FeedViewController.swift
//  Recipe App
//
//  Created by Alex Tang on 11/25/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import Network

struct FeedRecipe {
    let id: String
    let title: String
    let imageUrl: String
    let authorId: String
    let authorName: String
    let timestamp: Date
    let localImageName: String?
}

class FeedViewController: UIViewController {
    private var recipes: [FeedRecipe] = []
    private let db = Firestore.firestore()
    private var networkMonitor: NWPathMonitor?
    private var isConnected = true
    private var friendsListener: ListenerRegistration?
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        button.addTarget(self, action: #selector(addRecipeTapped), for: .touchUpInside)
        return button
    }()
   
   private lazy var tableView: UITableView = {
       let table = UITableView()
       table.translatesAutoresizingMaskIntoConstraints = false
       table.register(RecipeFeedCell.self, forCellReuseIdentifier: RecipeFeedCell.identifier)
       table.delegate = self
       table.dataSource = self
       table.separatorStyle = .none
       table.backgroundColor = .systemGray6
       return table
   }()

   private lazy var noConnectionView: UIView = {
       let view = UIView()
       view.backgroundColor = .systemRed
       view.translatesAutoresizingMaskIntoConstraints = false
       view.isHidden = true
       
       let label = UILabel()
       label.text = "No Internet Connection"
       label.textColor = .white
       label.translatesAutoresizingMaskIntoConstraints = false
       view.addSubview(label)
       
       NSLayoutConstraint.activate([
           label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
           label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
       ])
       
       return view
   }()

   override func viewDidLoad() {
       super.viewDidLoad()
       setupUI()
       setupNetworkMonitoring()
       title = "Feed"
       listenForFriendsUpdates()
       fetchRecipes()
   }
   
   private func setupNetworkMonitoring() {
       networkMonitor = NWPathMonitor()
       let queue = DispatchQueue(label: "NetworkMonitor")
       
       networkMonitor?.pathUpdateHandler = { [weak self] path in
           let isConnected = path.status == .satisfied
           DispatchQueue.main.async {
               self?.handleConnectionChange(isConnected: isConnected)
           }
       }
       
       networkMonitor?.start(queue: queue)
   }
   
   private func handleConnectionChange(isConnected: Bool) {
       self.isConnected = isConnected
       if isConnected {
           hideNoConnectionView()
           fetchRecipes()
       } else {
           showNoConnectionView()
       }
   }
   
   private func setupUI() {
       view.addSubview(tableView)
       view.addSubview(addButton)
       view.addSubview(noConnectionView)
               
       NSLayoutConstraint.activate([
           tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
           tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
           tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
           tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
           
           addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
           addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
           addButton.widthAnchor.constraint(equalToConstant: 44),
           addButton.heightAnchor.constraint(equalToConstant: 44),
           
           noConnectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
           noConnectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
           noConnectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
           noConnectionView.heightAnchor.constraint(equalToConstant: 44)
       ])
   }
   
    @objc private func addRecipeTapped() {
        let addVC = AddRecipeViewController()
        addVC.delegate = self
        let nav = UINavigationController(rootViewController: addVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    private func fetchRecipes() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        guard isConnected else {
            showNoConnectionView()
            return
        }
        recipes = []
        
        db.collection("users").document(currentUserId).getDocument { [weak self] document, error in
            guard let self = self,
                  let data = document?.data(),
                  let friendIds = data["friends"] as? [String] else {
                print("Error fetching friends: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.updateFeed(for: friendIds)
        }
    }
    
    private func listenForFriendsUpdates() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
            
        friendsListener = db.collection("users").document(currentUserId)
            .addSnapshotListener { [weak self] document, error in
                guard let self = self, let data = document?.data() else {
                    print("Error fetching user data: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                    
                if let friendIds = data["friends"] as? [String] {
                    self.updateFeed(for: friendIds)
                }
            }
    }
            
    private func updateFeed(for friendIds: [String]) {
        var userIds = friendIds
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        userIds.append(currentUserId)

        let group = DispatchGroup()
        var allRecipes: [FeedRecipe] = []

        for userId in userIds {
            group.enter()
            db.collection("users").document(userId).collection("recipes")
                .whereField("type", isEqualTo: "uploaded")
                .getDocuments { snapshot, error in
                    defer { group.leave() }

                    guard let documents = snapshot?.documents else { return }

                    let userRecipes = documents.compactMap { document -> FeedRecipe? in
                        let data = document.data()
                        guard let title = data["title"] as? String,
                                let timestamp = data["timestamp"] as? Double else {
                            return nil
                        }

                        return FeedRecipe(
                            id: document.documentID,
                            title: title,
                            imageUrl: data["imageUrl"] as? String ?? "",
                            authorId: userId,
                            authorName: data["authorName"] as? String ?? "Unknown Chef",
                            timestamp: Date(timeIntervalSince1970: timestamp),
                            localImageName: data["localImageName"] as? String
                        )
                    }

                    allRecipes.append(contentsOf: userRecipes)
                }
        }

        group.notify(queue: .main) {
            self.recipes = allRecipes.sorted { $0.timestamp > $1.timestamp }
            self.tableView.reloadData()
        }
    }
    
    private func showNoConnectionView() {
        UIView.animate(withDuration: 0.3) {
            self.noConnectionView.isHidden = false
        }
    }
    
    private func hideNoConnectionView() {
        UIView.animate(withDuration: 0.3) {
            self.noConnectionView.isHidden = true
        }
    }
    
    deinit {
        networkMonitor?.cancel()
        friendsListener?.remove()
    }
}

extension FeedViewController: UITableViewDelegate, UITableViewDataSource {
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return recipes.count
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       let cell = tableView.dequeueReusableCell(withIdentifier: RecipeFeedCell.identifier, for: indexPath) as! RecipeFeedCell
       cell.configure(with: recipes[indexPath.row])
       return cell
   }
   
   func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
       return 280 // Height for card with image
   }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recipe = recipes[indexPath.row]
        let detailVC = RecipeFeedDetailViewController()
        detailVC.recipe = recipe
        let nav = UINavigationController(rootViewController: detailVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

extension FeedViewController: AddRecipeDelegate {
    func didAddRecipe() {
        recipes = [] // Clear existing recipes
        fetchRecipes() // Refetch all recipes
    }
}
