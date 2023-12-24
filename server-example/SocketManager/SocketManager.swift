//
//  SocketManager.swift
//  server-example
//
//  Created by Akın Özcan on 4.12.2023.
//

import Foundation

class SocketManager {

    static let shared = SocketManager()
    private init() { }

    func startServer(port: UInt16) {
        let server = Server(port: port)
        try! server.start()
    }
}
