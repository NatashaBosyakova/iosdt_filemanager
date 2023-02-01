//
//  SetPassword.swift
//  MyFileManager
//
//  Created by Наталья Босякова on 11.01.2023.
//

import UIKit

import KeychainAccess

class PasswordScreen: UIViewController {
    
    let keychain = Keychain()
    var password: String = ""
    var isNeedRepeat = false
    
    private lazy var stackView: UIStackView = {
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.backgroundColor = UIColor.lightGray
        stackView.spacing = 18
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
        
    }()
    
    private lazy var checkButton: UIButton = {
        
        var config = UIButton.Configuration.filled()
        config.baseForegroundColor = .gray
        config.baseBackgroundColor = .systemGray6
        config.imagePadding = 5
        let button = UIButton(configuration: config)
        button.setTitle("Set password", for: .normal)
        button.addTarget(self, action: #selector(setOrCheckPassword), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
        
    }()
    
    private lazy var clearButton: UIButton = {
        
        var config = UIButton.Configuration.filled()
        config.baseForegroundColor = .gray
        config.baseBackgroundColor = .systemGray6
        config.imagePadding = 5
        let button = UIButton(configuration: config)
        button.setTitle("Clear password", for: .normal)
        button.addTarget(self, action: #selector(clearPassword), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
        
    }()
    
    private lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 50))
        textField.leftViewMode = .always
        textField.layer.cornerRadius = 6
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.borderWidth = 0.5
        textField.tag = 0
        textField.placeholder = "Password"
        textField.textColor = .black
        textField.isSecureTextEntry = true
        textField.autocapitalizationType = .none
        textField.clearButtonMode = .whileEditing
        textField.addTarget(self, action:  #selector(passwordTextFieldDidChange), for: .editingChanged)
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.password = keychain["password"] ?? ""
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setIsEnabled() {
        checkButton.isEnabled = passwordTextField.text!.count >= 4
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.setupGestures()
        view.backgroundColor = UIColor.lightGray
        
        addSubviews()
        setConstraints()
        setTitle()
        setIsEnabled()
        
    }
    
    private func addSubviews() {
            
        self.stackView.addArrangedSubview(self.passwordTextField)
        self.stackView.addArrangedSubview(self.checkButton)
        //self.stackView.addArrangedSubview(self.clearButton)

        self.view.addSubview(self.stackView)

    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            
            self.stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            self.stackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            self.stackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            self.stackView.heightAnchor.constraint(equalToConstant: 100),
            
       ])
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.forcedHidingKeyboard))
        self.view.addGestureRecognizer(tapGesture)
    }
        
    private func getTabBarController() -> UITabBarController {
        
        let fileManager = UINavigationController()
        fileManager.tabBarItem.title = "File Manager"
        fileManager.tabBarItem.image = UIImage(systemName: "folder.fill")
        fileManager.viewControllers.append(FileManagerViewController())

        let settings = UINavigationController()
        settings.tabBarItem.title = "Settings"
        settings.tabBarItem.image = UIImage(systemName: "gearshape.fill")
        settings.viewControllers.append(SettingsViewController())

        let tabBarController = UITabBarController()
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        tabBarController.viewControllers = [fileManager, settings]
        tabBarController.tabBar.layer.backgroundColor = UIColor.systemGray5.cgColor
        tabBarController.tabBar.tintColor = .orange
        
        return tabBarController
    }
    
    @objc private func didHideKeyboard(_ notification: Notification) {
        self.forcedHidingKeyboard()
    }
        
    private func setTitle() {
        
        if self.password != "" && !self.isNeedRepeat { // проверка пароля
            checkButton.setTitle("Enter password", for: .normal)
        }
        else if self.password != "" && self.isNeedRepeat { // повторный ввод пароля
            checkButton.setTitle("Repeat password", for: .normal)
        }
        else if self.password == "" && !self.isNeedRepeat { // установка пароля
            checkButton.setTitle("Set password", for: .normal)
        }
        
    }
    
    @objc private func passwordTextFieldDidChange() {
        setIsEnabled()
    }
    
    @objc private func clearPassword() {
        
        keychain[string: "password"] = ""
        self.password = ""
        setTitle()
            
    }
        
    @objc private func setOrCheckPassword() {
        
        if self.password != "" && !self.isNeedRepeat { // проверка пароля
            if self.password == passwordTextField.text! {
                let controller = getTabBarController()
                navigationController?.pushViewController(controller, animated: true)
            }
            else {
                self.isNeedRepeat = false
                
                let alert = UIAlertController(
                    title: "Error",
                    message: "Wrong password",
                    preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default))
                alert.view.tintColor = .black
                
                navigationController!.present(alert, animated: true, completion: nil)
            }
        }
        else if self.password != "" && self.isNeedRepeat { // повторный ввод пароля
            
            
            if self.password == passwordTextField.text! {
                self.isNeedRepeat = false
                keychain[string: "password"] = passwordTextField.text!
                
                let alert = UIAlertController(
                    title: "Success",
                    message: "Password set",
                    preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default))
                alert.view.tintColor = .black
                
                navigationController!.present(alert, animated: true, completion: nil)
            }
            else {
                self.isNeedRepeat = false
                self.password = ""
                
                let alert = UIAlertController(
                    title: "Error",
                    message: "Password mismatch",
                    preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default))
                alert.view.tintColor = .black
                
                navigationController!.present(alert, animated: true, completion: nil)
            }
        }
        else if self.password == "" && !self.isNeedRepeat { // установка пароля
            self.password = passwordTextField.text!
            self.isNeedRepeat = true
        }
        
        passwordTextField.text = ""
        setIsEnabled()
        setTitle()
        
     }
    
    @objc private func forcedHidingKeyboard() {
        self.view.endEditing(true)
    }
        
}
