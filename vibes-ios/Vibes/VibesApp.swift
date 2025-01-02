//
//  VibesApp.swift
//  Vibes
//
//  Created by Peter Yoon on 1/1/25.
//

import SwiftUI

@main
struct VibesApp: App {
    init() {
        // Set the global accent color for the app
        UINavigationBar.appearance().tintColor = UIColor(Color.appAccent)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
