//
//  ContentView.swift
//  PeerTalkPlaygroundWithSPM
//
//  Created by treastrain on 2021/05/14.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var helper = PeerTalkHelper()
    
    var body: some View {
        VStack {
            List(helper.messages, id: \.self) { message in
                Text(message)
            }
            HStack {
                TextField(
                    "Type here",
                    text: $helper.text,
                    onCommit: {
                        #if !os(macOS)
                        sendButtonAction()
                        #endif
                    }
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(
                    action: sendButtonAction,
                    label: {
                        Text("Send")
                            .bold()
                    }
                )
                .keyboardShortcut(.return)
            }
            .padding()
        }
    }
    
    func sendButtonAction() {
        helper.sendMessage()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
