//
//  PeerTalkHelper+PTChannelDelegate.swift
//  PeerTalkPlaygroundWithSPM
//
//  Created by treastrain on 2021/05/15.
//

import Foundation
import PeerTalk

extension PeerTalkHelper: PTChannelDelegate {
    #if os(iOS) || os(tvOS)
    func channel(_ channel: PTChannel, didAcceptConnection otherChannel: PTChannel, from address: PTAddress) {
        if self.peerChannel != nil {
            self.peerChannel?.cancel()
        }
        
        self.peerChannel = otherChannel
        self.peerChannel?.userInfo = address
        self.addMessage("✅ Connected to \(address)")
    }
    #endif
    
    func channel(_ channel: PTChannel, shouldAcceptFrame type: UInt32, tag: UInt32, payloadSize: UInt32) -> Bool {
        #if os(iOS) || os(tvOS)
        guard channel == self.peerChannel else {
            return false
        }
        #endif
        
        guard type == Settings.frameType else {
            print("Unexpected frame of type \(type)")
            channel.close()
            return false
        }
        
        return true
    }
    
    func channel(_ channel: PTChannel, didRecieveFrame type: UInt32, tag: UInt32, payload: Data?) {
        guard type == Settings.frameType else {
            print("Unexpected frame of type \(type)")
            channel.close()
            return
        }
        
        guard let payload = payload else {
            return
        }
        
        payload.withUnsafeBytes { buffer in
            let textBytes = buffer[(buffer.startIndex + MemoryLayout<UInt32>.size)...]
            if let message = String(bytes: textBytes, encoding: .utf8) {
                #if os(iOS) || os(tvOS)
                addMessage("💻 \(message)")
                #elseif os(macOS)
                addMessage("📱 \(message)")
                #else
                addMessage("❓ \(message)")
                #endif
            }
        }
    }
    
    func channelDidEnd(_ channel: PTChannel, error: Error?) {
        #if os(iOS) || os(tvOS)
        if let error = error {
            self.addMessage("❌ \(channel) ended with error: \(error)")
        } else {
            self.addMessage("📴 Disconnected from \(channel.userInfo)")
        }
        #elseif os(macOS)
        if let connectedDeviceID = self.connectedDeviceID,
           let deviceID = channel.userInfo as? NSNumber,
           connectedDeviceID.isEqual(to: deviceID) {
            self.didDisconnect(from: self.connectedDeviceID!)
        }
        
        if self.peerChannel == channel {
            self.addMessage("📴 Disconnected from \(channel.userInfo)")
            self.peerChannel = nil
        }
        #endif
    }
}
