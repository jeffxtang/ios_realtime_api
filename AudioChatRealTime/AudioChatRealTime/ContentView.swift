//
//  ContentView.swift
//  AudioChatRealTime
//
//  Created by Jeff Tang on 2/19/25.
//

import SwiftUI


import OpenAI
import SwiftUI

let OPENAI_API_KEY = "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"


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

struct ConversationView: View {
    @Bindable var conversation: Conversation  

    var body: some View {
        VStack {
          if (conversation.isListening || (conversation.getClient().getConnector() != nil && conversation.getClient().getConnector()!.getConnection().signalingState == .stable)) {
                Text("Listening...")
                .font(.headline)
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            } else {
                Text("Pick one!")
                .font(.headline)
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
        }
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
  
  func endWebSocket() {
    Task {
      await conversation?.stopHandlingVoice()
    }
  }

  func endWebRTC() {
    Task {
      self.conversation?.getClient().getConnector()!.getConnection().close()
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
  @State private var status: String = "Pick one!"
  @State private var isWebSocketButtonTapped = false
  @State private var isWebRTCButtonTapped = false
  
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
            if !isWebSocketButtonTapped {
                status = "Initializing WebSocket..."
                viewModel.initWebSocket()
                isWebSocketButtonTapped = true
                isWebRTCButtonTapped = false
            } else {
                status = "Pick one!"
                viewModel.endWebSocket()
                isWebSocketButtonTapped = false
            }
        }) {
            Text(isWebSocketButtonTapped ? "End" : "WebSocket")
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isWebSocketButtonTapped ? Color.red : (isWebRTCButtonTapped ? Color.gray : Color.green))
                .cornerRadius(8)
        }
        .disabled(isWebRTCButtonTapped)
        
        Spacer()
        
        Button(action: {
          if !isWebRTCButtonTapped {
              status = "Initializing WebRTC..."
              viewModel.initWebRTC()
              isWebRTCButtonTapped = true
              isWebSocketButtonTapped = false
          } else {
            status = "Pick one!"
            viewModel.endWebRTC()
            isWebRTCButtonTapped = false
          }
        }) {
            Text(isWebRTCButtonTapped ? "End" : "WebRTC")
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isWebRTCButtonTapped ? Color.red : (isWebSocketButtonTapped ? Color.gray : Color.green))
                .cornerRadius(8)
        }
        .disabled(isWebSocketButtonTapped)
      }
      .padding()
      
      if let conversation = viewModel.conversation {
          ConversationView(conversation: conversation)
      }
      else {
        Text(status)
          .font(.headline)
          .foregroundColor(.blue)
          .padding()
          .frame(maxWidth: .infinity)
          .background(Color.gray.opacity(0.2))
          .cornerRadius(8)
      }
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
