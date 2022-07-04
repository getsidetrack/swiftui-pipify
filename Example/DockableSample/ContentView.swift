//
//  ContentView.swift
//  DockableSample
//
//  Created by James Sherlock on 01/07/2022.
//

import SwiftUI
import Dockable

struct ContentView: View {
    @StateObject var controller = DockableController()
    @StateObject var controllerTwo = DockableController()
    
    var body: some View {
        VStack {
            Text("SwiftUI Dockable")
                .font(.title)
            
            Button("Launch Basic Example") {
                controller.enabled.toggle()
            }
            
            Text("Dockable View (Tap on me!)")
                .foregroundColor(.red)
                .fontWeight(.medium)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .dockable(controller: controllerTwo)
                .padding(.top)
                .onTapGesture {
                    controllerTwo.enabled.toggle()
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dockable(controller: controller, view: BasicExample(controller: controller))
    }
}

struct BasicExample: View {
    @State var mode: Int = 0
    @State var counter: Int = 0
    
    @ObservedObject var controller: DockableController
    
    var body: some View {
        Group {
            switch mode {
            case 0:
                VStack {
                    Text("Width: \(Int(controller.renderSize.width))")
                    Text("Height: \(Int(controller.renderSize.height))")
                }
                .foregroundColor(.green)
            case 1:
                Text("Counter: \(counter)")
                    .foregroundColor(.blue)
                    .frame(width: 300, height: 100)
            default:
                Color.red
                    .overlay { Text("Counter: \(counter)").foregroundColor(.white) }
                    .frame(width: 100, height: 300)
            }
        }
        .task {
            controller.isPlayPauseEnabled = false
            await updateMode()
        }
        .task {
            await updateCounter()
        }
        .onChange(of: controller.isPlaying) { isPlaying in
            print("Playback \(isPlaying ? "is playing" : "is not playing")")
        }
    }
    
    private func updateCounter() async {
        counter += 1
        try? await Task.sleep(nanoseconds: 10_000_000) // 10 milliseconds
        await updateCounter()
    }
    
    private func updateMode() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000 * 5) // 5 seconds
        mode += 1
        
        if mode == 3 {
            mode = 0
        }
        
        await updateMode()
    }
}
