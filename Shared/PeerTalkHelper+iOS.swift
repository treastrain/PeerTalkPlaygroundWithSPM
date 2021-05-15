//
//  PeerTalkHelper+iOS.swift
//  PeerTalkPlaygroundWithSPM
//
//  Created by treastrain on 2021/05/15.
//

import Foundation
import PeerTalk

#if os(iOS) || os(tvOS)
extension PeerTalkHelper {
    func setupClientSideChannel() {
        let channel = PTChannel(protocol: nil, delegate: self)
        channel.listen(on: Settings.port, IPv4Address: INADDR_LOOPBACK) { error in
            if let error = error {
                self.addMessage("❌ Failed to listen on 127.0.0.1:\(Settings.port) \(error)")
            } else {
                self.addMessage("🎵 Listening on 127.0.0.1:\(Settings.port)")
                self.serverChannel = channel
            }
        }
    }
}
#endif
