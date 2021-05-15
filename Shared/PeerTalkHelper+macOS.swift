//
//  PeerTalkHelper+macOS.swift
//  PeerTalkPlaygroundWithSPM
//
//  Created by treastrain on 2021/05/15.
//

import Foundation
import PeerTalk

#if os(macOS)
extension PeerTalkHelper {
    func startListeningForDevices() {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(forName: .deviceDidAttach, object: PTUSBHub.shared(), queue: nil) { notification in
            let deviceID = notification.userInfo?["DeviceID"] as! NSNumber
            print("PTUSBDeviceDidAttachNotification: \(deviceID)")
            
            Settings.notConnectedQueue.async {
                if self.connectingToDeviceID == nil ||
                    self.connectingToDeviceID?.isEqual(to: deviceID) ?? false {
                    self.disconnectFromCurrentChannel()
                    self.connectingToDeviceID = deviceID
                    self.connectedDeviceProperties = notification.userInfo?["Properties"] as? [String : Any] ?? [:]
                    self.enqueueConnectToUSBDevice()
                }
            }
        }
        
        notificationCenter.addObserver(forName: .deviceDidDetach, object: PTUSBHub.shared(), queue: nil) { notification in
            let deviceID = notification.userInfo?["DeviceID"] as! NSNumber
            print("PTUSBDeviceDidDetachNotification: \(deviceID)")
            
            if self.connectingToDeviceID?.isEqual(to: deviceID) ?? false {
                self.connectedDeviceID = nil
                self.connectedDeviceProperties.removeAll()
                if self.peerChannel != nil {
                    self.peerChannel?.close()
                }
            }
        }
    }
    
    @objc
    func enqueueConnectToUSBDevice() {
        Settings.notConnectedQueue.async {
            DispatchQueue.main.async {
                self.connectToUSBDevice()
            }
        }
    }
    
    func connectToUSBDevice() {
        guard let deviceID = self.connectingToDeviceID else {
            return
        }
        
        let channel = PTChannel(protocol: nil, delegate: self)
        channel.userInfo = deviceID as Any
        
        channel.connect(to: Int32(Settings.port), over: PTUSBHub.shared(), deviceID: deviceID) { error in
            if let error = error as NSError? {
                if error.domain == PTUSBHubErrorDomain, error.code == PTUSBHubErrorConnectionRefused.rawValue {
                    // self.addMessage("❌ Failed to connect to device #\(channel.userInfo): \(error)")
                } else {
                    self.addMessage("❌ Failed to connect to device #\(channel.userInfo): \(error)")
                }
                if channel.userInfo as? NSNumber == deviceID {
                    self.perform(#selector(self.enqueueConnectToUSBDevice), with: nil, afterDelay: Settings.reconnectDelay)
                }
            } else {
                self.connectedDeviceID = deviceID
                self.peerChannel = channel
                self.addMessage("✅ Connected to device #\(deviceID)\n\(self.connectedDeviceProperties)")
            }
        }
    }
    
    func disconnectFromCurrentChannel() {
        if self.connectedDeviceID != nil,
           self.peerChannel != nil {
            self.peerChannel?.close()
            self.peerChannel = nil
        }
    }
    
    @objc
    func enqueueConnectToLocalIPv4Port() {
        Settings.notConnectedQueue.async {
            DispatchQueue.main.async {
                self.connectToLocalIPv4Port()
            }
        }
    }
    
    func connectToLocalIPv4Port() {
        let channel = PTChannel(protocol: nil, delegate: self)
        channel.connect(to: Settings.port, IPv4Address: INADDR_LOOPBACK) { error, address in
            if let error = error as NSError? {
                if error.domain == NSPOSIXErrorDomain,
                   (error.code == ECONNREFUSED || error.code == ETIMEDOUT) {
                    // print("This is an expected state")
                } else {
                    self.addMessage("❌ Failed to connect to 127.0.0.1:\(Settings.port): \(error)")
                }
                self.perform(#selector(self.enqueueConnectToLocalIPv4Port), with: nil, afterDelay: Settings.reconnectDelay)
            } else {
                self.disconnectFromCurrentChannel()
                channel.userInfo = address as Any
                self.peerChannel = channel
                self.addMessage("✅ Connected to \(address!)")
            }
        }
    }
    
    func didDisconnect(from deviceID: NSNumber) {
        self.addMessage("📴 Disconnected from device: \(deviceID)")
        if self.connectedDeviceID?.isEqual(to: deviceID) ?? false {
            self.willChangeValue(forKey: "connectedDeviceID")
            self.connectedDeviceID = nil
            self.didChangeValue(forKey: "connectedDeviceID")
        }
    }
}
#endif
