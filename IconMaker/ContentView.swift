//
//  ContentView.swift
//  IconMaker
//
//  Created by lChen on 2023/6/12.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    @State private var dragOver = false
    @State private var inputPath = "Click or drag image file here."
    @State private var outputPath = ""
    @State private var imageStatus = "plus.circle.fill"
    @State private var imageStatusColor: Color = .gray
    @State private var platform = 0

    var body: some View {
        VStack {
//            Spacer().frame(height: 5)
            Group {
                AsyncImage(url: URL(string: inputPath)) { image in
                    ZStack(alignment: .bottomTrailing) {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                        Image(systemName: imageStatus)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .foregroundColor(imageStatusColor)
                    }
                } placeholder: {
                    ZStack(alignment: .bottomTrailing) {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                        Image(systemName: imageStatus)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .foregroundColor(imageStatusColor)
                    }
                }
                .frame(width: 75, height: 75)
                .padding()
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    if let provider = providers.first(where: { $0.canLoadObject(ofClass: URL.self) } ) {
                        let _ = provider.loadObject(ofClass: URL.self) { object, error in
                            if let url = object {
                                let imageExtensions = ["png", "jpg", "gif"]
                                let pathExtention = url.pathExtension
                                if imageExtensions.contains(pathExtention) {
                                    inputPath = "\(url)"
                                    imageStatus = "checkmark.circle.fill"
                                    imageStatusColor = .clear
                                } else {
                                    inputPath = "Unsupported content type, please choose again."
                                    imageStatus = "x.circle.fill"
                                    imageStatusColor = .red

                                }
                                
                            }
                        }
                        return true
                    }
                    return false
                }
                .onTapGesture {
                    self.browseButtonAction("$inputPath")
                }
                .disabled(viewModel.isUIDisable)
                Text(inputPath)
            }
            Spacer().frame(height: 15)
            Group {
                HStack {
                    Spacer().frame(width: 25)
                    Text("Output Path")
                        .fixedSize()
                    Spacer().frame(width: 10)
                    TextField("", text: $outputPath)
                        .cornerRadius(5)
                        .frame(minWidth: 150)
                        .disabled(viewModel.isUIDisable)
                    Button(action: {
                        self.browseButtonAction("$outputPath")
                    }) {
                        Text("Browse")
                    }
                    .frame(minWidth: 80)
                    .disabled(viewModel.isUIDisable)
                    .buttonStyle(.borderedProminent)
                    Spacer().frame(width: 10)
                }.frame(height: 24)
            }
            Spacer().frame(height: 15)
            Group {
                HStack {
                    Text("Platform").bold()
                        .fixedSize()
                    VStack{ Divider() }
                }.frame(height: 24)
                HStack(spacing: 20) {
                    Spacer().frame(width: 5)
                    Picker(selection: $platform,
                           label: Text("")) {
                        Text("iOS").tag(0).frame(width: 40, alignment: .leading)
                        Text("macOS").tag(1).frame(width: 60, alignment: .leading)
                        Text("watchOS").tag(2).frame(width: 60, alignment: .leading)

                    }
                    .pickerStyle(.radioGroup)
                    .horizontalRadioGroupLayout()
                    .disabled(viewModel.isUIDisable)
                    .frame(height: 24)
                    .fixedSize()
                    Spacer()
                }
            }
            Spacer().frame(height: 15)
            Group {
                Spacer().frame(height: 15)
                HStack {
                    if viewModel.isUIDisable {
                        Spacer().frame(width: 35)
                        ProgressView().controlSize(.small)
                        Spacer().frame(width: 10)
                    }
                    Text(viewModel.searchProgress)
                    Spacer()
                    Button(action: {
                        self.generatorButtonAction()
                    }) {
                        Text("Generator").frame(minWidth: 60)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isUIDisable)
                    Spacer().frame(width: 15)
                }.frame(height: 24)
            }
        }
        .frame(width: 500, height: 350)
        .padding()
    }
    
    func browseButtonAction(_ sender: String) {
        let openPanel = NSOpenPanel()
        if sender == "$inputPath" {
            openPanel.canChooseDirectories = false
            openPanel.allowsMultipleSelection = false
            openPanel.allowedContentTypes = [.image]
        } else if sender == "$outputPath" {
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
        }
        let okButtonPressed = openPanel.runModal() == .OK
        if okButtonPressed {
            // Update the path text field
            let path = openPanel.url?.path
            
            imageStatusColor = .clear
            if sender == "$inputPath" {
                inputPath = "file://" + path!
                imageStatus = "checkmark.circle.fill"
            } else if sender == "$outputPath" {
                outputPath = path!
            }
        }
    }
    
    func showAlert(with style: NSAlert.Style, title: String?, subtitle: String?) {
        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = title ?? ""
        alert.informativeText = subtitle ?? ""
        alert.runModal()
    }

    func generatorButtonAction() {
        
        var errorMessage = ""

        if imageStatusColor == .red {
            errorMessage = "Please check the image."
        } else if outputPath == "" {
            errorMessage = "Path cannot be empty."
        } else if !FileManager.default.fileExists(atPath: outputPath) {
            errorMessage = "Please check the path."
        }
        guard errorMessage == "" else {
            showAlert(with: .warning, title: "Error", subtitle: errorMessage)
            return
        }
        let input = inputPath.replacingOccurrences(of: "file://", with: "")
        let nameOfFile = input.components(separatedBy: "/").last ?? "zipFile"
        let outputFolder = createDirectory(nameOfFile)
//        print(input)
        if viewModel.generate(input, outputFolder, platform) {
            imageStatusColor = .green
        } else {
            imageStatusColor = .red
            showAlert(with: .warning, title: "Error", subtitle: errorMessage)
        }
    }
    
    func createDirectory(_ name: String) -> String {
        let docURL = URL(string: outputPath)!
        let imageExtensions = [".png", ".jpg", ".gif"]
        var fileName = name
        for ext in imageExtensions {
            fileName = fileName.replacingOccurrences(of: ext, with: "")
        }
        var dataPath = docURL.appendingPathComponent("AppIcon_\(fileName).appiconset")
        var count = 0
        while FileManager.default.fileExists(atPath: dataPath.path) {
            count += 1
            dataPath = docURL.appendingPathComponent("AppIcon_\(fileName)_\(count).appiconset")
        }
        do {
            try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
            return dataPath.path
        } catch {
            print(error.localizedDescription)
            return outputPath
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
