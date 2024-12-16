//
//  RecipeFeedCell.swift
//  Recipe App
//
//  Created by Alex Tang on 11/25/24.
//

import UIKit

class RecipeFeedCell: UITableViewCell {
    static let identifier = "RecipeFeedCell"
    
    private let cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()
    
    private let recipeImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        iv.backgroundColor = .systemGray6
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.numberOfLines = 0
        return label
    }()
    
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textColor = .gray
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(cardView)
        cardView.addSubview(recipeImageView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(authorLabel)
        cardView.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            // Card View
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Image View
            recipeImageView.topAnchor.constraint(equalTo: cardView.topAnchor),
            recipeImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            recipeImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            recipeImageView.heightAnchor.constraint(equalToConstant: 150),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: recipeImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            // Author Label
            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            authorLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            authorLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            // Time Label
            timeLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            timeLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with recipe: FeedRecipe) {
        titleLabel.text = recipe.title
        authorLabel.text = "By \(recipe.authorName)"
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        timeLabel.text = formatter.localizedString(for: recipe.timestamp, relativeTo: Date())
        
        // Reset image view
        recipeImageView.image = UIImage(systemName: "photo")
        
        // Try to load local image first
        if let localImageName = recipe.localImageName,
           let localImage = getLocalImage(name: localImageName) {
            recipeImageView.image = localImage
            return
        }
        
        // If no local image, load from URL
        if let imageUrl = URL(string: recipe.imageUrl) {
            URLSession.shared.dataTask(with: imageUrl) { [weak self] data, response, error in
                guard let self = self,
                      let data = data,
                      let image = UIImage(data: data),
                      error == nil else {
                    return
                }
                
                DispatchQueue.main.async {
                    UIView.transition(with: self.recipeImageView,
                                    duration: 0.3,
                                    options: .transitionCrossDissolve) {
                        self.recipeImageView.image = image
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        recipeImageView.image = UIImage(systemName: "photo")
        titleLabel.text = nil
        authorLabel.text = nil
        timeLabel.text = nil
    }
}
