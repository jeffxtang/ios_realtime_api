//
//  ContentView.swift
//  AudioChatRealTime
//
//  Created by Jeff Tang on 2/19/25.
//

import SwiftUI


import OpenAI
import SwiftUI

let OPENAI_API_KEY = "xxxxx"

struct MessageBubble: View {
  let message: Item.Message

  var text: String {
    message.content.map { $0.text ?? "" }.joined()
  }

  var body: some View {
    HStack {
      if message.role == .user {
        Spacer()
      }

      ZStack(alignment: .topTrailing) {
        Text(text)
          .foregroundColor(.white)
          .multilineTextAlignment(.leading)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(message.role == .user ? .blue : .secondary)
          .cornerRadius(20)
      }

      if message.role == .assistant {
        Spacer()
      }
    }
    .padding(message.role == .user ? .leading : .trailing, 48)
  }
}

class ConversationViewModel: ObservableObject {
  @Published var conversation: Conversation?
    
  func initWebSocket() {
        Task {
          let conversation = Conversation(authToken: OPENAI_API_KEY)
            DispatchQueue.main.async {
                self.conversation = conversation
                try! conversation.startListening()
            }
        }
    }
  
  func initWebRTC() {
      Task {
        let conversation = await Conversation(authToken: OPENAI_API_KEY, webRTC: true)
          DispatchQueue.main.async {
              self.conversation = conversation
          }
      }
  }
}



struct ContentView: View {
  @StateObject private var viewModel = ConversationViewModel()
  @State private var newMessage: String = ""
  @State private var status: String = ""
  @State private var areButtonsEnabled = true
  
  var messages: [Item.Message] {
    viewModel.conversation?.entries.compactMap { switch $0 {
      case let .message(message): return message
      default: return nil
    } } ?? []
  }
  
  var body: some View {
    VStack(spacing: 20) {
      ScrollView {
                VStack(spacing: 12) {
                    ForEach(messages, id: \.id) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
      }
      .frame(maxHeight: 500)

      HStack(spacing: 12) {
        
        Button(action: {
          status = "Initializing WebSocket..."
          viewModel.initWebSocket()
          areButtonsEnabled = false
        }) {
            Text("WebSocket")
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(areButtonsEnabled ? Color.green : Color.gray)
                .cornerRadius(8)
        }
        .disabled(!areButtonsEnabled)
        
        Spacer()
        
        Button(action: {
          status = "Initializing WebRTC..."
          viewModel.initWebRTC()
          areButtonsEnabled = false
        }) {
            Text("WebRTC")
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(areButtonsEnabled ? Color.green : Color.gray)
                .cornerRadius(8)
        }
        .disabled(!areButtonsEnabled)
      }
      .padding()
      
      Text(status)
        .font(.headline)
        .foregroundColor(.blue)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
    .navigationTitle("Chat")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
    }
  }

  func sendMessage() {
    guard newMessage != "" else { return }

    Task {
      try await viewModel.conversation!.send(from: .user, text: newMessage)
      newMessage = ""
    }
  }
}
