// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import NMSSH
import WebKit

class TerminalViewController: UIViewController, NMSSHChannelDelegate, UIKeyInput, UITextInputTraits {
    
    static var htmlTerminal: String {
        return try! String(contentsOfFile: Bundle.main.path(forResource: "terminal", ofType: "html")!)
    }
    
    @IBOutlet weak var webView: WKWebView!
    var pwd: String?
    var console = ""
    var command: String?
    var consoleANSI = ""
    var consoleHTML = ""
    var ctrlKey: UIBarButtonItem!
    var ctrl = false
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        return false
    }
    
    override var inputAccessoryView: UIView? {
        let toolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        toolbar.barStyle = .black
        
        ctrlKey = UIBarButtonItem(title: "ctrl", style: .done, target: self, action: #selector(insertKey(_:)))
        ctrlKey.tag = 1
        
        // ⬅︎⬆︎⬇︎➡︎
        let leftArrow = UIBarButtonItem(title: "⬅︎", style: .done, target: self, action: #selector(insertKey(_:)))
        leftArrow.tag = 2
        let upArrow = UIBarButtonItem(title: "⬆︎", style: .done, target: self, action: #selector(insertKey(_:)))
        upArrow.tag = 3
        let downArrow = UIBarButtonItem(title: "⬇︎", style: .done, target: self, action: #selector(insertKey(_:)))
        downArrow.tag = 4
        let rightArrow = UIBarButtonItem(title: "➡︎", style: .done, target: self, action: #selector(insertKey(_:)))
        rightArrow.tag = 5
        
        let items = [ctrlKey, leftArrow, upArrow, downArrow, rightArrow] as [UIBarButtonItem]
        toolbar.items = items
        toolbar.sizeToFit()
        
        return toolbar
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if webView.backgroundColor != .black {
            guard let session = ConnectionManager.shared.session else {
                navigationController?.popViewController(animated: true)
                
                return
            }
            
            // Show commands history
            let history = UIBarButtonItem(image: #imageLiteral(resourceName: "history"), style: .plain, target: self, action: #selector(showHistory(_:)))
            navigationItem.rightBarButtonItem = history
            
            navigationItem.largeTitleDisplayMode = .never
            
            webView.backgroundColor = .black
            webView.loadHTMLString(TerminalViewController.htmlTerminal, baseURL: Bundle.main.bundleURL)
            
            // Session
            do {
                
                session.channel.delegate = self
                
                let clearLastFromHistory = "history -d $(history 1)"
                
                if let pwd = pwd {
                    try session.channel.write("cd '\(pwd)'; \(clearLastFromHistory)\n")
                }
                
                try session.channel.write("clear; \(clearLastFromHistory)\n")
                
                becomeFirstResponder()
                
                if let command = self.command {
                    try session.channel.write("\(command); sleep 0.1; \(clearLastFromHistory)\n")
                }
            } catch {
            }
        }
    }

    @objc func writeText(_ text: String) { // Write command without writing it in the textView
        do {
            try ConnectionManager.shared.session?.channel.write(text)
        } catch {
        }
    }
    
    @objc func showHistory(_ sender: UIBarButtonItem) { // Show commands history
        
        do {
            guard let session = ConnectionManager.shared.filesSession else { return }
            let history = try session.channel.execute("cat .pisth_history").components(separatedBy: "\n")
                
            let commandsVC = CommandsTableViewController()
            commandsVC.title = "History"
            commandsVC.commands = history
            commandsVC.modalPresentationStyle = .popover
                
            if let popover = commandsVC.popoverPresentationController {
                popover.barButtonItem = sender
                popover.delegate = commandsVC
                    
                self.present(commandsVC, animated: true, completion: {
                    commandsVC.tableView.scrollToRow(at: IndexPath(row: history.count-1, section: 0), at: .bottom, animated: true)
                })
            }
        } catch {
            print("Error sending command: \(error.localizedDescription)")
        }
    }
    
    // Insert special key
    @objc func insertKey(_ sender: UIBarButtonItem) {
        if sender.tag == 1 { // ctrl
            ctrl = true
            sender.isEnabled = false
        } else if sender.tag == 2 { // Left arrow
            writeText(Keys.arrowLeft)
        } else if sender.tag == 3 { // Up arrow
            writeText(Keys.arrowUp)
        } else if sender.tag == 4 { // Down arrow
            writeText(Keys.arrowDown)
        } else if sender.tag == 5 { // Right arrow
            writeText(Keys.arrowRight)
        }
    }
    
    // MARK: NMSSHChannelDelegate
    
    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {
        DispatchQueue.main.async {
            self.consoleANSI = self.consoleANSI+message
            
            self.webView.loadHTMLString(TerminalViewController.htmlTerminal.replacingOccurrences(of: "$_ANSIOUTPUT_", with: self.consoleANSI.javaScriptEscapedString), baseURL: Bundle.main.bundleURL)
        }
    }
    
    func channelShellDidClose(_ channel: NMSSHChannel!) {
        DispatchQueue.main.async {
            DirectoryTableViewController.disconnected = true
            
            self.navigationController?.popToRootViewController(animated: true, completion: {
                AppDelegate.shared.navigationController.pushViewController(self, animated: true)
            })
        }
    }
    
    // MARK: UIKeyInput
    
    func insertText(_ text: String) {
        do {
            if !ctrl {
                try ConnectionManager.shared.session?.channel.write(text)
            } else {
                try ConnectionManager.shared.session?.channel.write(Keys.ctrlKey(from: text))
                ctrl = false
                ctrlKey.isEnabled = true
            }
        } catch {}
    }
    
    func deleteBackward() {
        do {
            try ConnectionManager.shared.session?.channel.write(Keys.ctrlH)
        } catch {}
    }
    
    var hasText: Bool {
        return true
    }
    
    // MARK: UITextInputTraits
    
    var keyboardAppearance: UIKeyboardAppearance = .dark
    var autocorrectionType: UITextAutocorrectionType = .no
}
