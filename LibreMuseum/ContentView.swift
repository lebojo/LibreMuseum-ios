//
//  ContentView.swift
//  LibreMuseum
//
//  Created by Jordan Chap on 8/6/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                NavigationStack {
                    List {

                    }
                    .navigationTitle(Constants.MuseumName)
                    .toolbar {
                        ToolbarItem {
                            Button("Settings", systemImage: "gear") {

                            }
                            .sheet(isPresented: .constant(false)) {
                                List {
                                    Section("Device settings") {
                                        Text("")
                                    }
                                    Section("local data") {
                                        Text("Used storage: \(00)\("gb")")
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Tab("map", systemImage: "map") {
                Text("PlaceHolder")
            }

            Tab(role: .search) {
                Text("PlaceHolder")
            }
        }
    }
}

#Preview {
    ContentView()
}
