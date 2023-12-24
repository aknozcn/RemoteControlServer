//
//  ServerConnection.swift
//  RemoteControlSocket
//
//  Created by Akın Özcan on 2.12.2023.
//

import Foundation
import Network
import CoreAudio
import AppKit
import RemoteControl

enum ActionType: String {
    case volume
    case openUrl
    case currentVolume
    case mute
    case unMute
    case none
}

@available(macOS 10.14, *)
class ServerConnection {
    
    let maximumLength = 65536
    
    private static var nextID: Int = 0
    let  connection: NWConnection
    let id: Int
    

    init(nwConnection: NWConnection) {
        connection = nwConnection
        id = ServerConnection.nextID
        ServerConnection.nextID += 1
    }
    
    var didStopCallback: ((Error?) -> Void)? = nil
    
    func start() {
        print("connection \(id) will start")
        connection.stateUpdateHandler = self.stateDidChange(to:)
        setupReceive()
        connection.start(queue: .main)

    }
    
    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .waiting(let error):
            connectionDidFail(error: error)
        case .ready:
            print("connection \(id) ready")
        case .failed(let error):
            connectionDidFail(error: error)
        default:
            break
        }
    }

    private func getHost() ->  NWEndpoint.Host? {
        switch connection.endpoint {
        case .hostPort(let host , _):
            return host
        default:
            return nil
        }
    }
    
    private func setupReceive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: maximumLength) { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                let message = String(data: data, encoding: .utf8)
                print("connection \(self.id) did receive, data: \(data as NSData) string: \(message ?? "-") ip: \(self.getHost() ?? "")")
                self.send(data: data)

                if let msg = message {
                    let components = msg.components(separatedBy: ",")
                    
                    if ActionType.volume.rawValue == components[0] {
                        if let floatValue = Float(components[1]) {
                            RemoteControl.shared.setVolume(Float32(floatValue))
                        }
                    }
                    
                    if ActionType.openUrl.rawValue == components[0] {
                        let url = URL(string: components[1])!
                        if NSWorkspace.shared.open(url) {
                            print("default browser was successfully opened")
                        }
                    }
                    
                    if ActionType.mute.rawValue == components[0] {
                        if let floatValue = Float(components[1]) {
                            RemoteControl.shared.setVolume(Float32(floatValue))
                        }
                    }
                    
                    if ActionType.unMute.rawValue == components[0] {
                        let volume = RemoteControl.shared.getTempVolume()
                        RemoteControl.shared.setVolume(volume)
                    }
                }
               
            }
            if isComplete {
                self.connectionDidEnd()
            } else if let error = error {
                self.connectionDidFail(error: error)
            } else {
                self.setupReceive()
            }
        }
    }

    
    func send(data: Data) {
        self.connection.send(content: data, completion: .contentProcessed( { error in
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
            print("connection \(self.id) did send, data: \(data as NSData)")
        }))
    }
    
    func stop() {
        print("connection \(id) will stop")
    }
    
    
    
    private func connectionDidFail(error: Error) {
        print("connection \(id) did fail, error: \(error)")
        stop(error: error)
    }
    
    private func connectionDidEnd() {
        print("connection \(id) did end")
        stop(error: nil)
    }
    
    private func stop(error: Error?) {
        connection.stateUpdateHandler = nil
        connection.cancel()
        if let didStopCallback = didStopCallback {
            self.didStopCallback = nil
            didStopCallback(error)
        }
    }
}
