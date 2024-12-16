import UIKit
import FirebaseFirestore

class FriendProfileViewController: UIViewController {
    @IBOutlet weak var friendsCountLabel: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var recipeCount: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var friend: Friend?
    private var friendsCount: Int = 0
    private var uploadedRecipes: [String] = []
    private var generatedRecipes: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupUserImage()
        setupTableView()
        fetchFriendsCount()
        fetchRecipes()
    }
    
    private func setupView() {
        guard let friend = friend else { return }
        emailLabel.text = friend.email
        nameLabel.text = "Chef " + friend.name
    }
    
    private func setupUserImage() {
        userImage.backgroundColor = .systemGray5
        userImage.layer.cornerRadius = userImage.frame.width / 2
        userImage.clipsToBounds = true
        userImage.layer.borderWidth = 2
        userImage.layer.borderColor = UIColor.systemGray4.cgColor
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RecipeCell")
        tableView.sectionHeaderTopPadding = 0
    }
    
    private func fetchFriendsCount() {
        guard let friendId = friend?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(friendId).getDocument { [weak self] document, error in
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
    
    private func fetchRecipes() {
        guard let friendId = friend?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(friendId).collection("recipes").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching recipes: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            var uploaded: [String] = []
            var generated: [String] = []
            
            for document in documents {
                let data = document.data()
                if let title = data["title"] as? String,
                   let type = data["type"] as? String {
                    if type == "uploaded" {
                        uploaded.append(title)
                    } else if type == "generated" {
                        generated.append(title)
                    }
                }
            }
            
            self?.uploadedRecipes = uploaded
            self?.generatedRecipes = generated
            
            DispatchQueue.main.async {
                self?.recipeCount.text = "\(uploaded.count + generated.count)"
                self?.tableView.reloadData()
            }
        }
    }
}

extension FriendProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? uploadedRecipes.count : generatedRecipes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath)
        let recipe = indexPath.section == 0 ? uploadedRecipes[indexPath.row] : generatedRecipes[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = recipe
        cell.contentConfiguration = config
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Uploaded Recipes" : "Generated Recipes"
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemGray6
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.text = section == 0 ? "Uploaded Recipes" : "Generated Recipes"
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}
