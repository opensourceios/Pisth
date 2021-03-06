// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// Table View Cell that represents a remote or local file.
class FileTableViewCell: UITableViewCell {
    
    /// File's icon.
    @IBOutlet weak var iconView: UIImageView!
    
    /// Filename.
    @IBOutlet weak var filename: UILabel!
    
    /// File permissions.
    @IBOutlet weak var permssions: UILabel!
    
    /// `UITableViewCell`'s `canPerformAction(_:, withSender:)` function.
    ///
    /// - Returns: `true` to allow moving and renaming file if this cell represents a remote file.
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if let directoryTableViewController = (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)?.visibleViewController as? DirectoryTableViewController {
            
            if directoryTableViewController.files![directoryTableViewController.tableView.indexPath(for: self)?.row ?? 0].isDirectory {
                
                return (action == #selector(moveFile(_:)) || action == #selector(renameFile(_:)))
            }
        }
        
        return (action == #selector(UIResponderStandardEditActions.copy(_:)) || action == #selector(moveFile(_:)) || action == #selector(UIResponderStandardEditActions.copy(_:)) || action == #selector(renameFile(_:)))
    }
    
    /// `UIViewController`'s `canBecomeFirstResponder` variable.
    ///
    /// Returnns true to allow actions.
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    /// Rename the remote file represented by the cell.
    @objc func renameFile(_ sender: Any) {
        if let directoryTableViewController = (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)?.visibleViewController as? DirectoryTableViewController {
            
            directoryTableViewController.checkForConnectionError(errorHandler: {
                directoryTableViewController.showError()
            })
            
            let fileToRename = directoryTableViewController.files![directoryTableViewController.tableView.indexPath(for: self)!.row]
            
            let renameAlert = UIAlertController(title: "Write new file name", message: "Write new name for \(fileToRename.filename!).", preferredStyle: .alert)
            renameAlert.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "New file name"
                textField.text = fileToRename.filename
            })
            
            renameAlert.addAction(UIAlertAction(title: "Rename", style: .default, handler: { (_) in
                guard let newFileName = renameAlert.textFields?[0].text else { return }
                guard let session = ConnectionManager.shared.filesSession else { return }
                
                if session.sftp.moveItem(atPath: directoryTableViewController.directory.nsString.appendingPathComponent(fileToRename.filename), toPath: directoryTableViewController.directory.nsString.appendingPathComponent(newFileName)) {
                   
                    directoryTableViewController.reload()
                } else {
                    let errorAlert = UIAlertController(title: "Error renaming file!", message: nil, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    directoryTableViewController.present(errorAlert, animated: true, completion: nil)
                }
            }))
            
            renameAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            directoryTableViewController.present(renameAlert, animated: true, completion: nil)
        }
    }
    
    /// Move remote file represented by the cell.
    @objc func moveFile(_ sender: Any) {
        if let directoryTableViewController = (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)?.visibleViewController as? DirectoryTableViewController {
            
            directoryTableViewController.checkForConnectionError(errorHandler: {
                directoryTableViewController.showError()
            })
            
            Pasteboard.local.filePath = directoryTableViewController.directory.nsString.appendingPathComponent(directoryTableViewController.files![directoryTableViewController.tableView.indexPath(for: self)!.row].filename)
            
            let dirVC = DirectoryTableViewController(connection: directoryTableViewController.connection, directory: directoryTableViewController.directory)
            dirVC.navigationItem.prompt = "Select a directory where move file"
            dirVC.delegate = dirVC
            DirectoryTableViewController.action = .moveFile
            
            let navVC = UINavigationController(rootViewController: dirVC)
            navVC.navigationBar.barStyle = .black
            navVC.navigationBar.isTranslucent = true
            directoryTableViewController.present(navVC, animated: true, completion: {
                dirVC.navigationItem.setRightBarButtonItems([UIBarButtonItem(title: "Move here", style: .plain, target: dirVC, action: #selector(dirVC.moveFile))], animated: true)
                dirVC.navigationItem.setLeftBarButtonItems([UIBarButtonItem(title: "Done", style: .done, target: dirVC, action: #selector(dirVC.close))], animated: true)
            })
        }
    }
}
