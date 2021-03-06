// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// Git branches table view controller to display Git remote branches at `repoPath`.
class GitRemotesTableViewController: GitBranchesTableViewController {
    
    /// `UIViewController`'s `viewDidLoad` function.
    ///
    /// List remote branches for Git repo.
    override func viewDidLoad() {
        
        _ = try? ConnectionManager.shared.filesSession!.channel.execute("git -C '\(repoPath!)' remote update --prune")
        
        if let result = try? ConnectionManager.shared.filesSession!.channel.execute("git -C '\(repoPath!)' branch -r") {
            for branch in result.components(separatedBy: "\n") {
                if !branch.contains("/HEAD ") && branch.replacingOccurrences(of: " ", with: "") != "" {
                    self.branches.append(branch.replacingOccurrences(of: " ", with: ""))
                }
            }
        }
        
        tableView.tableFooterView = UIView()
        navigationItem.setRightBarButtonItems(nil, animated: false)
    }
    
    // MARK: - Table view data source
    
    /// `UITableViewController`'s `tableView(_:, cellForRowAt:)` function.
    ///
    /// - Returns: An `UITableViewCell` with title as branch name.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "branch", for: indexPath)
        
        guard let title = cell.viewWithTag(1) as? UILabel else { return cell }
        guard let isCurrent = cell.viewWithTag(2) as? UILabel else { return cell }
        
        title.text = branches[indexPath.row]
        isCurrent.isHidden = (current != branches[indexPath.row])
        
        return cell
    }
    
    // MARK: - Table view delegate
    
    /// `UITableViewController`'s `tableView(_:, didSelectRowAt:)` function.
    ///
    /// View commits for selected branch.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let handler = selectionHandler {
            handler(self, indexPath)
            return
        }
        
        launch(command: "git -C '\(repoPath!)' --no-pager log --graph \(branches[indexPath.row])", withTitle: "Commits for \(branches[indexPath.row])")
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
