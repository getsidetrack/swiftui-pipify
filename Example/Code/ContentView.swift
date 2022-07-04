//
//  Copyright 2022 • Sidetrack Tech Limited
//

import SwiftUI
import Pipify

struct ContentView: View {
    @State var isPresentedOne = false
    @State var isPresentedTwo = false
    
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pipify(isPresented: $isPresentedTwo, content: BasicExample.init)
    }
}
