//
//  PeerTalkHelper.swift
//  PeerTalkPlaygroundWithSPM
//
//  Created by treastrain on 2021/05/15.
//

import Foundation
import PeerTalk

enum Settings {
    static let port: in_port_t = 50621
    static let frameType: UInt32 = 1
    
    #if os(macOS)
    static let reconnectDelay: TimeInterval = 1.0
    static let notConnectedQueue = DispatchQueue(label: "jp.tret.PeerTalkPlaygroundWithSPM.notConnectedQueue")
    #endif
}

class PeerTalkHelper: NSObject, ObservableObject {
    @Published var messages: [String] = []
    @Published var text = ""
    
    var peerChannel: PTChannel?
    
    #if os(iOS) || os(tvOS)
    var serverChannel: PTChannel?
    #endif
    
    #if os(macOS)
    var connectingToDeviceID: NSNumber?
    var connectedDeviceID: NSNumber?
    var connectedDeviceProperties: [String : Any] = [:]
    #endif
    
    override init() {
        super.init()
        
        #if os(iOS) || os(tvOS)
        self.setupClientSideChannel()
        #elseif os(macOS)
        // Start listening for device attached/detached notifications
        self.startListeningForDevices()
        // Start trying to connect to local IPv4 port
        self.enqueueConnectToLocalIPv4Port()
        self.addMessage("⌛ Ready for action — connecting at will.")
        #endif
    }
    
    deinit {
        #if os(iOS) || os(tvOS)
        if self.serverChannel != nil {
            self.serverChannel?.close()
        }
        #endif
    }
    
    func sendMessage() {
        guard !self.text.isEmpty else {
            return
        }
        
        print(#function, self.text, Date())
        
        #if os(iOS) || os(tvOS)
        addMessage("📱 \(self.text)")
        #elseif os(macOS)
        addMessage("💻 \(self.text)")
        #else
        addMessage("❓ \(self.text)")
        #endif
        
        send(self.text)
    }
    
    func addMessage(_ message: String) {
        self.messages.insert(message, at: 0)
    }
    
    private func send(_ message: String) {
        guard let channel = self.peerChannel else {
            self.addMessage("❌ Can not send the message - not connected: \"\(message)\"")
            return
        }
        
        var message = message
        let payload = message.withUTF8 { buffer -> Data in
            var data = Data()
            data.append(CFSwapInt32HostToBig(UInt32(buffer.count)).data)
            data.append(buffer)
            return data
        }
        channel.sendFrame(type: Settings.frameType, tag: PTFrameNoTag, payload: payload) { error in
            if let error = error {
                self.addMessage("❌ Can not send the message - error: \(error) \"\(message)\"")
            }
        }
    }
}

extension FixedWidthInteger {
    var data: Data {
        var bytes = self
        return Data(bytes: &bytes, count: MemoryLayout.size(ofValue: self))
    }
}
