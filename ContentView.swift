//
//  ContentView.swift
//  MaskingPractice
//
//  Created by 김인섭 on 1/8/24.
//

import SwiftUI
import PencilKit

struct ContentView: View {
    
    @StateObject var viewModel = CanvasManager()
    
    var body: some View {
        VStack {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .background(GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                viewModel.size = proxy.size
                            }
                    })
            }
            Button {
                viewModel.showCanvas = true
            } label: {
                Text("Open Image Editor")
            }
        }
        .onAppear { viewModel.image = .init(named: "document") }
        .fullScreenCover(isPresented: $viewModel.showCanvas, content: {
            VStack(spacing: 0, content: {
                HStack {
                    Spacer()
                    Button("save") {
                        viewModel.saveImage()
                        viewModel.showCanvas = false
                    }
                }.padding(.horizontal)
                CanvasView(
                    image: viewModel.image,
                    canvas: viewModel.canvas,
                    rect: viewModel.size)
            })
        })
    }
}

@MainActor class CanvasManager: ObservableObject {
    
    @Published var image: UIImage?
    var size: CGSize = .zero
    let canvas = PKCanvasView()
    @Published var showCanvas = false
    
    func saveImage(){
        self.image = canvas.imageWithBackgroundImage(image, size: size)
    }
}

extension PKCanvasView {
    
    func imageWithBackgroundImage(_ bgImage: UIImage?, size: CGSize) -> UIImage? {
        var image: UIImage?
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let imageRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
        UIGraphicsGetCurrentContext()
        if let bgImage { bgImage.draw(in: imageRect) }
        drawing.image(from: drawing.bounds, scale: 0).draw(in: drawing.bounds)
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

struct CanvasView: UIViewRepresentable {
    
    let image: UIImage?
    let canvas: PKCanvasView
    let toolPicker = PKToolPicker()
    let rect: CGSize
    
    func makeUIView(context: Context) -> PKCanvasView {
        
        canvas.isOpaque = false
        canvas.backgroundColor = .clear
        canvas.drawingPolicy = .anyInput
        
        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        let subView = canvas.subviews.first!
        subView.addSubview(imageView)
        subView.sendSubviewToBack(imageView)
        
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        canvas.becomeFirstResponder()
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) { }
}
