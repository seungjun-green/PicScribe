//
//  ContentView.swift
//  Pic Scribe
//
//  Created by SeungJun Lee on 5/30/24.
//

import PhotosUI
import UIKit
import CoreGraphics
import SwiftUI
import CoreML
import CoreVideo


struct ContentView: View {
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var currentUIImage: UIImage?
    @State private var resizedImage: UIImage?
    @State private var currentImage: Image?
    @State private var generatedCaption = "Select an image to generate a caption."
    @State private var isLoading: Bool = false

    let modelManager = ModelManager()
    
    
    func generate(img_embeddings: MLMultiArray) {
        
        
        var token_array = Array(repeating: 0, count: 32)
        token_array[0] = 101
        var token_MLarray = modelManager.convertToMLMultiArray(token_array: [token_array])
        
        for i in 0...30 {
            do {
                let logit = try modelManager.decoder.prediction(image_embeddings: img_embeddings, txt: token_MLarray!).var_783
                
                // get the logit
                let pred = try modelManager.extractSlice(from: logit, at: i)
                
                // 2. apply softmax
                
                // 3. get the index with higest vlaue
                let next_token_id = modelManager.indexOfMaxValue(in: pred)
                
            
                            
                if next_token_id == 102 {
                    break
                }
                
                token_array[i+1] = Int(truncating: next_token_id as NSNumber)
                token_MLarray = modelManager.convertToMLMultiArray(token_array: [token_array])
                
                generatedCaption = modelManager.constructString(data: [token_array])
                
            } catch {
                print("Some error happened! :(")
                generatedCaption = "Some error happened during generation. Please try again."
            }
            
            
        }
                
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                
                Spacer()
                
                VStack{
                    
                    
                    PhotosPicker(selection: $selectedPhoto , matching: .images) {
                        Label("Select a photo", systemImage: "photo")
                            .frame(width: geo.size.width * 0.5, height: geo.size.height * 0.07)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                                
                    }
                        
                }
               
                
                Spacer()
                
                
                
                VStack{
                    if let currentImage {
                        ZStack {
                            
                            currentImage
                                .resizable()
                                .frame(width: geo.size.width * 0.9, height: geo.size.height * 0.6)
                                .scaledToFill()
                                .blur(radius: 10)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                            
                            
                            
                            if  currentUIImage?.size.width ?? 100 > currentUIImage?.size.height ?? 100 {
                                currentImage
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width * 0.9)
                            } else {
                                currentImage
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: geo.size.height * 0.6)
                            }
                            
                        }.frame(width: geo.size.width * 0.9, height: geo.size.height * 0.6)
                        
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .overlay(Text("No Photo Selected").foregroundColor(.gray))
                            .frame(width: geo.size.width * 0.9, height: geo.size.height * 0.6)
                            .shadow(radius: 5)
                    }
                }
                
                
                Spacer()
                
                Button(action: {
                    isLoading = true
                    DispatchQueue.global(qos: .background).async {

                    
                        let image_feature =  modelManager.passEncoder(currentUIImage: currentUIImage)
                        generate(img_embeddings: image_feature!)
                        
                        DispatchQueue.main.async {
                            isLoading = false
                        }
                    }
                    
                    
                }, label: {
                    
                    VStack{
                        if isLoading {
                            ProgressView()
                        } else {
                            Label("Generate Caption", systemImage: "cpu")
                                .frame(width: geo.size.width * 0.5, height: geo.size.height * 0.07)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                    }
                    
                    
                })
                .disabled(currentImage == nil)
                
                Spacer()
                
                HStack{
                    Spacer()
                    VStack{
                        CaptionCardView(caption: generatedCaption).frame(width: geo.size.width * 0.9, height: geo.size.height * 0.2)
                    }.frame(width: geo.size.width * 0.9, height: geo.size.height * 0.1)
                    Spacer()
                }.frame(height: geo.size.height * 0.1)
                
                
                Spacer()
            }
            
        }
        .onChange(of: selectedPhoto) {
            Task {
                if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        currentUIImage = uiImage
                        currentImage = Image(uiImage: uiImage)
                        return
                    }
                }
                generatedCaption = "Failed to load image."
                print("Failed")
            }
        }
    }
    
    
}


struct CaptionCardView: View {
    var caption: String
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color.gray.opacity(0.95)
        default:
            return Color.gray.opacity(0.05)
        }
    }
    
    var body: some View {
        Text(caption)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(backgroundColor)
                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5)
            )
            
    }
}
