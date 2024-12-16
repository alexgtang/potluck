import UIKit
import FirebaseFirestore
import FirebaseAuth
struct Friend {
    let uid: String
    let name: String
    let email: String

    init(data: [String: Any]) {
        self.uid = data["uid"] as? String ?? ""
        self.name = data["name"] as? String ?? "Unknown"
        self.email = data["email"] as? String ?? "No Email"
    }
}

class FriendsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    private var db = Firestore.firestore()
    private var userId: String? {
        return Auth.auth().currentUser?.uid
    }

    private var allUsers: [Friend] = [] // All users
    private var filteredUsers: [Friend] = [] // Search results
    private var friends: [Friend] = [] // Current user's friends
    private var currentMode: Mode = .myFriends

    enum Mode {
        case findUsers
        case myFriends
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        setupSearchController()
        setupTableView()
        setupSegmentedControl()
        fetchAllUsers()
        fetchFriends()
    }

    // MARK: - Setup Methods
    private func setupSearchController() {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Users"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func setupTableView() {
        print("Table view hidden: \(tableView.isHidden)")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UserCell")
    }

    private func setupSegmentedControl() {
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
    }

    // MARK: - Firestore Fetch Methods
    private func fetchAllUsers() {
        db.collection("users").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
                return
            }

            self?.allUsers = snapshot?.documents.compactMap { document in
                Friend(data: document.data())
            } ?? []

            self?.filteredUsers = self?.allUsers ?? []
            print("Fetched users: \(self?.allUsers.map { $0.name } ?? [])") // Debug
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                print("Table view reloaded")
            }
        }
    }


    private func fetchFriends() {
        guard let userId = userId else { return }

        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching friends: \(error.localizedDescription)")
                return
            }

            guard let friendIds = document?.data()?["friends"] as? [String] else {
                print("No friends found.")
                return
            }
                
            self?.fetchFriendsDetails(friendIds: friendIds)
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }

    private func fetchFriendsDetails(friendIds: [String]) {
        guard !friendIds.isEmpty else { return }

        db.collection("users").whereField(FieldPath.documentID(), in: friendIds).getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching friends details: \(error.localizedDescription)")
                return
            }

            self?.friends = snapshot?.documents.compactMap { document in
                Friend(data: document.data())
            } ?? []
            self?.tableView.reloadData()
        }
    }

    private func addFriend(friendId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(userId).updateData([
            "friends": FieldValue.arrayUnion([friendId])
        ]) { error in
            if let error = error {
                print("Error adding friend: \(error.localizedDescription)")
            } else {
                print("Friend added successfully")
                self.fetchFriends() // Refresh the friends list
            }
        }
    }

    // MARK: - Segment Control Handling
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        currentMode = sender.selectedSegmentIndex == 0 ? .myFriends : .findUsers
        print("Current mode: \(currentMode)") // Debug
        tableView.reloadData()
    }
}

// MARK: - UISearchResultsUpdating
extension FriendsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text, !query.isEmpty else {
            filteredUsers = allUsers // Show full list if search is empty
            tableView.reloadData()
            return
        }

        filteredUsers = allUsers.filter { user in
            user.name.lowercased().contains(query.lowercased()) ||
            user.email.lowercased().contains(query.lowercased())
        }
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension FriendsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = currentMode == .findUsers ? filteredUsers.count : friends.count
        print("Number of rows in current mode (\(currentMode)): \(count)") // Debug
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
        let user = currentMode == .findUsers ? filteredUsers[indexPath.row] : friends[indexPath.row]

        // Configure text labels
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        cell.textLabel?.lineBreakMode = .byTruncatingTail
        cell.detailTextLabel?.lineBreakMode = .byTruncatingTail

        // Configure the button or checkmark
        if currentMode == .findUsers {
            // Check if this user is already a friend
            if friends.contains(where: { $0.uid == user.uid }) {
                cell.accessoryType = .checkmark
                cell.accessoryView = nil
            } else {
                cell.accessoryType = .none
                let addButton = UIButton(type: .system)
                addButton.setTitle("Add Friend", for: .normal)
                addButton.frame = CGRect(x: 0, y: 0, width: 100, height: 30)
                addButton.tag = indexPath.row
                addButton.addTarget(self, action: #selector(addFriendTapped(_:)), for: .touchUpInside)
                cell.accessoryView = addButton
            }
        } else {
            cell.accessoryView = nil
            cell.accessoryType = .none
        }

        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            // Deselect the row
            tableView.deselectRow(at: indexPath, animated: true)
            
            // Get the selected user
            let selectedUser = currentMode == .findUsers ? filteredUsers[indexPath.row] : friends[indexPath.row]
            
            // Instantiate FriendProfileViewController
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let profileVC = storyboard.instantiateViewController(withIdentifier: "FriendProfileViewController") as? FriendProfileViewController {
                profileVC.friend = selectedUser
                navigationController?.pushViewController(profileVC, animated: true)
            }
    }




    @objc private func addFriendTapped(_ sender: UIButton) {
        let selectedUser = filteredUsers[sender.tag]
        addFriend(friendId: selectedUser.uid)
    }
}
