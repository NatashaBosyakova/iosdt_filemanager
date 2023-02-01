//
//  Settings.swift
//  MyFileManager
//
//  Created by Наталья Босякова on 01.02.2023.
//

import UIKit

import KeychainAccess

enum SortBy: String {
    case alphabetically = "Sort from A to Z"
    case notAlphabetically = "Sort from Z to A"
}

class SettingsViewController: UIViewController {
    
    let keychain = Keychain()
    
    var sortBy: SortBy = .alphabetically
    
    private var segmentedControlSortBy: UISegmentedControl {
        let segmentedControl = UISegmentedControl (
            items: [
                SortBy.alphabetically.rawValue,
                SortBy.notAlphabetically.rawValue])
        
        segmentedControl.addTarget(self, action: #selector(saveSettings), for: .valueChanged)
                
        let sortBy = UserDefaults.standard.string(forKey: "SortBy") ?? SortBy.alphabetically.rawValue
        segmentedControl.selectedSegmentIndex = sortBy == SortBy.alphabetically.rawValue ? 0 : 1
        self.sortBy = sortBy == SortBy.alphabetically.rawValue  ? SortBy.alphabetically : SortBy.notAlphabetically
        
        return segmentedControl
    }
    
    private lazy var stackView: UIStackView = {
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 18
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
        
    }()
    
    private lazy var buttonChangePassward: UIButton = {
        
        var config = UIButton.Configuration.filled()
        config.baseForegroundColor = .gray
        config.baseBackgroundColor = .systemGray6
        config.imagePadding = 5
        let button = UIButton(configuration: config)
        button.setTitle("Change password", for: .normal)
        button.addTarget(self, action: #selector(changePassword), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
        
    }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.navigationItem.titleView?.backgroundColor = .orange
        view.backgroundColor = .systemGray3
        
        addSubviews()
        setConstraints()
        
    }

    @objc private func saveSettings() {
                
        DispatchQueue.main.async {
            let sortBy: SortBy = self.sortBy == .alphabetically ? .notAlphabetically : .alphabetically
            self.sortBy = sortBy
            UserDefaults.standard.set(self.sortBy == .alphabetically ? SortBy.alphabetically.rawValue : SortBy.notAlphabetically.rawValue, forKey: "SortBy")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "settingsСhanged"), object: nil)
       }
        
    }
    
    private func addSubviews() {
            
        self.stackView.addArrangedSubview(self.segmentedControlSortBy)
        self.stackView.addArrangedSubview(self.buttonChangePassward)
        
        self.view.addSubview(self.stackView)

    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            
            self.stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            self.stackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            self.stackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            self.stackView.heightAnchor.constraint(equalToConstant: 100),

       ])
    }
    
    @objc private func changePassword() {
        let alertController = UIAlertController(title: "Set password", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Enter password"
            textField.isSecureTextEntry = true
        }
        
        let actionOK = UIAlertAction(title: "OK", style: .default) { action in
            if let text = alertController.textFields?[0].text, text != "" && text.count >= 4 {
                self.repeatPassword(password: text)
            }
            else {
                let alert = UIAlertController(
                    title: "Error",
                    message: "Password must be 4 characters or more",
                    preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default))
                alert.view.tintColor = .black
                
                self.navigationController!.present(alert, animated: true, completion: nil)
            }
        }
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(actionOK)
        alertController.addAction(actionCancel)

        navigationController!.present(alertController, animated: true)
    }
    
    
    func repeatPassword(password: String) {
        let alertController = UIAlertController(title: "Repeat password", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Enter password"
            textField.isSecureTextEntry = true
        }
        
        let actionOK = UIAlertAction(title: "OK", style: .default) { action in
            if password == alertController.textFields?[0].text {
                self.keychain[string: "password"] = password
                
                let alert = UIAlertController(
                    title: "Success",
                    message: "Password set",
                    preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default))
                alert.view.tintColor = .black
                
                self.navigationController!.present(alert, animated: true, completion: nil)
            }
            else {
                let alert = UIAlertController(
                    title: "Error",
                    message: "Password mismatch",
                    preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default))
                alert.view.tintColor = .black
                
                self.navigationController!.present(alert, animated: true, completion: nil)
            }
        }
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(actionOK)
        alertController.addAction(actionCancel)

        self.navigationController!.present(alertController, animated: true)
    }
    
}
