# ios_realtime_api

Working iOS demo app using WebSocket and WebRTC with OpenAI Realtime API.

The app uses my [fork](https://github.com/jeffxtang/swift-realtime-openai) of the Swift SDK for OpenAI's Realtime API package [here](https://github.com/m1guelpf/swift-realtime-openai) to support both WebRTC and WebSocket. 

To run the app, simply open the project in Xcode, replace OPENAI_API_KEY in ContentView.swift with your key, set your iOS signing team, and build and run on your iPhone. The audio chat with OpenAI Realtime API can't run on iOS simulator. 
