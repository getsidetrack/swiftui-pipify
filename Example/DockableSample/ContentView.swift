//
//  ContentView.swift
//  DockableSample
//
//  Created by James Sherlock on 01/07/2022.
//

import SwiftUI
import Dockable

struct ContentView: View {
    @ObservedObject var controller = DockableController()
    
    var body: some View {
        VStack {
            Text("SwiftUI Dockable")
                .font(.title)
            
            Button("Launch Basic Example") {
                print("button pressed")
                controller.enabled.toggle()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dockable(controller: controller, view: BasicExample())
    }
}

struct BasicExample: View {
    @State var mode: Int = 0
    
    var body: some View {
        Group {
            switch mode {
            case 0:
                Text("Text Ideal Size")
                    .foregroundColor(.green)
            case 1:
                Text("Text Fixed Size")
                    .foregroundColor(.blue)
                    .frame(width: 300, height: 100)
            default:
                Color.red
                    .frame(width: 100, height: 300)
            }
        }
        .task {
            await updateMode()
        }
    }
    
    private func updateMode() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000 * 5) // 5 seconds
        mode += 1
        
        if mode == 3 {
            mode = 0
        }
        
        if mode < 100 { // artificial number greater than the number of modes we support to cycle infinitely
            await updateMode()
        }
    }
}
