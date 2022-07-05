//
//  Copyright 2022 • Sidetrack Tech Limited
//

import SwiftUI
import Pipify

struct PipifyLoadingBarView: View {
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var progress: Double = 0
    
    var body: some View {
        Text("Loading...")
            .padding()
            .foregroundColor(.red)
            .pipBindProgress(progress: $progress)
            .onReceive(timer) { _ in
                let newProgress = progress + 0.05
                
                if newProgress > 1 {
                    progress = 0
                } else {
                    progress = newProgress
                }
            }
    }
    
}
