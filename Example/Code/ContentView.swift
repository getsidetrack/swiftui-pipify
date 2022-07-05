//
//  Copyright 2022 • Sidetrack Tech Limited
//

import SwiftUI
import Pipify

struct ContentView: View {
    @State var isPresentedOne = false
    @State var isPresentedTwo = false
    @State var isPresentedThree = false
    @State var isPresentedFour = false
    
    var body: some View {
        VStack {
            Text("SwiftUI Pipify")
                .font(.title)
            
            Button("Launch Basic Example") {
                isPresentedTwo.toggle()
            }
            
            Text("Pipify View (Tap on me!)")
                .foregroundColor(.red)
                .fontWeight(.medium)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .pipify(isPresented: $isPresentedOne)
                .padding(.top)
                .onTapGesture {
                    isPresentedOne.toggle()
                }
            
            Button("Basic Example") { isPresentedThree.toggle() }
                .pipify(isPresented: $isPresentedThree) {
                    Text("Example Three")
                        .foregroundColor(.red)
                        .padding()
                        .onPipSkip { _ in }
                        .onPipPlayPause { _ in }
                }
            
            Button("Progress Bar") { isPresentedFour.toggle() }
                .pipify(isPresented: $isPresentedFour) { PipifyLoadingBarView() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pipify(isPresented: $isPresentedTwo, content: BasicExample.init)
    }
}
