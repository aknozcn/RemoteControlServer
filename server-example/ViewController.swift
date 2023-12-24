//
//  ViewController.swift
//  server-example
//
//  Created by Akın Özcan on 30.10.2023.
//

import Cocoa
import Network

final class ViewController: NSViewController {

    var isServer = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        SocketManager.shared.startServer(port: 5001)

    }

    override var representedObject: Any? {
        didSet {
        }
    }
}

