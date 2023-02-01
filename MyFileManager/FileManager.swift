//
//  FileManager.swift
//  MyFileManager
//
//  Created by Наталья Босякова on 09.01.2023.
//

import UIKit

enum ContentType {
    case folder
    case file
}

struct Content {
    var type: ContentType
    var fileName: String
    init (fileName: String, type: ContentType) {
        self.fileName = fileName
        self.type = type
    }
}

protocol FileManagerServiceProtocol {
    
    var path: String { get set }
    
    func contentsOfDirectory() -> [Content]
    
    func createDirectory(folderName: String)
    
    func createFile(image: UIImage)
    
    func removeContent(content: Content)
}

class FileManagerService: FileManagerServiceProtocol {
    
    var path: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    func contentsOfDirectory() -> [Content] {
        
        var content: [Content] = []
        let files = (try? FileManager.default.contentsOfDirectory(atPath: path)) ?? []
        for fileName in files {
            var type: ContentType = .file
            let fullPath = path + "/" + fileName
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir) && isDir.boolValue == true {type = .folder}
            content.append(Content(fileName: fileName, type: type))
        }
        
        let sortBy = UserDefaults.standard.string(forKey: "SortBy") ?? SortBy.alphabetically.rawValue
        if sortBy == SortBy.alphabetically.rawValue {
            content = content.sorted(by: {$0.fileName < $1.fileName})
        }
        else {
            content = content.sorted(by: {$0.fileName > $1.fileName})
        }
        
        return content
    }
    
    func createDirectory(folderName: String) {
        let newDirectoryPath = self.path + "/" + folderName
        try? FileManager.default.createDirectory(atPath: newDirectoryPath, withIntermediateDirectories: false)
    }
    
    func createFile(image: UIImage) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddhhmmss"

        let filename = dateFormatter.string(from: Date()) + ".jpg"
        let fullPath = self.path + "/" + filename
        let url = NSURL.fileURL(withPath: fullPath)
        do {
            try image.jpegData(compressionQuality: 1.0)?.write(to: url, options: .atomic)

        } catch {
            print(error)
        }
    }
    
    func removeContent(content: Content) {
        let fullPath = self.path + "/" + content.fileName
        try? FileManager.default.removeItem(atPath: fullPath)
    }
}

class FileManagerViewController: UIViewController {
    
    var fileManager = FileManagerService()
    
    private lazy var tableViewFiles: UITableView = {
        let tableView = UITableView(frame: CGRectZero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .systemGray3
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        view.backgroundColor = .orange
        
        addSubviews()
        setConstraints()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.refreshTable),
            name: NSNotification.Name(rawValue: "settingsСhanged"),
            object: nil)
        
    }
    
    @objc func refreshTable() {
        DispatchQueue.main.async {
            self.tableViewFiles.reloadData()
        }
    }
    
    private func addSubviews() {
        
        let barButtonNewFolder = UIBarButtonItem(title: "New Folder", style: .plain, target: self, action: #selector(newFolder))
        let barButtonNewPicture = UIBarButtonItem(title: "New Picture", style: .plain, target: self, action: #selector(newPicture))
        barButtonNewFolder.tintColor = .white
        barButtonNewPicture.tintColor = .white
        navigationItem.rightBarButtonItems = [barButtonNewFolder, barButtonNewPicture]
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "< Back", style: .plain, target: self, action: #selector(goBack))
        navigationItem.leftBarButtonItem?.tintColor = .white
        
        navigationItem.leftBarButtonItem?.isEnabled = false
        
        view.addSubview(tableViewFiles)
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            
            self.tableViewFiles.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            self.tableViewFiles.leftAnchor.constraint(equalTo: view.leftAnchor),
            self.tableViewFiles.rightAnchor.constraint(equalTo: view.rightAnchor),
            self.tableViewFiles.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
       ])
    }
    
    @objc func goBack(sender: UIButton!) {
        let currentFolder = String(URL(filePath: fileManager.path).lastPathComponent)
        let newLenght = fileManager.path.count - currentFolder.count - 1
        let newPath = String(fileManager.path.prefix(newLenght))
        
        fileManager.path = newPath
        
        navigationItem.leftBarButtonItem?.isEnabled = URL(filePath: fileManager.path).lastPathComponent != "Documents"
        
        self.tableViewFiles.reloadData()
    }
    
    @objc func newFolder(sender: UIButton!) {
        getFolderName(in: self) { text in
            self.fileManager.createDirectory(folderName: text)
            self.tableViewFiles.reloadData()
        }
    }
    
    @objc func newPicture(sender: UIButton!) {
        getPicture(in: self)
    }
    
    func getFolderName(in viewController: UIViewController, completion: @escaping (_ text: String) -> Void) {
        let alertController = UIAlertController(title: "New folder's name", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Enter name"
        }
        
        let actionOK = UIAlertAction(title: "OK", style: .default) { action in
            if let text = alertController.textFields?[0].text, text != "" {
                completion(text)
            }
        }
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(actionOK)
        alertController.addAction(actionCancel)

        viewController.present(alertController, animated: true)
    }
    
    
    func getPicture(in viewController: UIViewController) {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary;
            imagePicker.allowsEditing = true
            viewController.present(imagePicker, animated: true, completion: nil)
        }
    }
}

extension FileManagerViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            fileManager.createFile(image: image)
            self.tableViewFiles.reloadData()
        }
    }
}

extension FileManagerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileManager.contentsOfDirectory().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let cell = self.tableViewFiles.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .systemGray3
        cell.textLabel?.text = fileManager.contentsOfDirectory()[indexPath.row].fileName
        cell.accessoryType = fileManager.contentsOfDirectory()[indexPath.row].type == .folder ? .disclosureIndicator : .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            fileManager.removeContent(content: fileManager.contentsOfDirectory()[indexPath.row])
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
        
    func tableView(_ tableView: UITableView, titleForHeaderInSection
                                section: Int) -> String? {
        var url = URL(filePath: fileManager.path)
        var lastPathComponent = url.lastPathComponent
        var title = ""
        while lastPathComponent != "Documents" {
            title = title == "" ? lastPathComponent :  lastPathComponent + " / " + title
            url.deleteLastPathComponent()
            lastPathComponent = url.lastPathComponent
        }
        
        return "Documents" + (title == "" ? "" : " / " + title)

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if fileManager.contentsOfDirectory()[indexPath.row].type == .folder {
            fileManager.path = fileManager.path + "/" + fileManager.contentsOfDirectory()[indexPath.row].fileName
            navigationItem.leftBarButtonItem?.isEnabled = URL(filePath: fileManager.path).lastPathComponent != "Documents"
            self.tableViewFiles.reloadData()
        }
    }
}
