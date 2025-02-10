//
//  ContentView.swift
//  Speech-to-Image-Classifier
//
//  Created by Kennan Gauthier on 2/6/25.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var model = FrameHandler()
    
    var body: some View {
        FrameView(image: model.frame)
            .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
