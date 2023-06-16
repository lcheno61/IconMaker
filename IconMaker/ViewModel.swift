//
//  ViewModel.swift
//  IconMaker
//
//  Created by lChen on 2023/6/12.
//

import Foundation
import AppKit

extension ContentView {
    class ViewModel: ObservableObject {
        @Published var isUIDisable = false
        @Published var searchProgress = ""
        
        var dataLock: NSLock?
        let iosArray: [CGFloat] = [40, 60, 58, 87, 76, 114, 80, 120, 120, 180, 128, 192, 136, 152, 166, 1024]
        let iosScaleArray = [2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 2, 2, 1]
        let macosArray: [CGFloat] = [16, 32, 32, 64, 128, 256, 256, 512, 512, 1024]
        let macosScaleArray = [1, 2, 1, 2, 1, 2, 1, 2, 1, 2]
        let watchosArray: [CGFloat] = [44, 48, 54, 58, 60, 64, 66, 80, 86, 88, 92, 100, 102, 108, 172, 196, 216, 234, 258, 1024]
        let watchosScaleArray = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1]

        init() {
            dataLock = NSLock()
        }

        func generate(_ inputPath: String, _ outputPath: String, _ platforms: Int ) -> Bool {
            guard !inputPath.contains("file://") else { return false }
            guard let image = NSImage(contentsOf: URL(fileURLWithPath: inputPath)) else { return false }
            dataLock = NSLock()
            isUIDisable = true
            var sizeArray = [CGFloat]()
            var scaleArray = [Int]()
            var outputFileName = [String]()
            switch platforms {
                case 0:
                    sizeArray = iosArray
                    scaleArray = iosScaleArray
                case 1:
                    sizeArray = macosArray
                    scaleArray = macosScaleArray

                case 2:
                    sizeArray = watchosArray
                    scaleArray = watchosScaleArray

                default:
                    break
            }

            for i in 0 ..< sizeArray.count {
                let targetSize = CGSizeMake(sizeArray[i], sizeArray[i])
                var px = Int(sizeArray[i]) / scaleArray[i]
                switch sizeArray[i] {
                    case 54, 86, 166:
                        let size = Int(sizeArray[i]) + 1
                        px = size / scaleArray[i]
                    default:
                        break
                }
                let fileName = "Icon-App-\(px)x\(px)@\(scaleArray[i])x.png"
                let fileNameWithPath = outputPath + "/" + fileName
                if let resizedImage = image.resized(to: targetSize) {
                    resizedImage.writePNG(toURL: URL(fileURLWithPath: fileNameWithPath))
                    outputFileName.append(fileName)
                } else {
                    outputFileName.append("__nil__")
                }
            }
            createJSON(outputPath, outputFileName, platforms)
            isUIDisable = false
            dataLock = NSLock()
//            print("sizeSet count: \(sizeSet.count)")
//            print("imageArray count: \(imageArray.count)")
            return true
        }
        
        
        func createJSON(_ outputPath: String, _ array: [String], _ platforms: Int) {
            guard array.count > 0 else { return }
            var jsonString = "{\n"
            jsonString = jsonString + "  \"images\" : [\n"
            switch platforms {
            case 0:
                let iOSjson = iOSJSON(array)
                jsonString = jsonString + iOSjson
            case 1:
                let iOSjson = macOSJSON(array)
                jsonString = jsonString + iOSjson
            case 2:
                let iOSjson = watchOSJSON(array)
                jsonString = jsonString + iOSjson
            default:
                break
            }
            jsonString = jsonString + "  ],\n"
            jsonString = jsonString + "  \"info\" : {\n"
            jsonString = jsonString + "    \"author\" : \"xcode\",\n"
            jsonString = jsonString + "    \"version\" : 1\n"
            jsonString = jsonString + "  }\n"
            jsonString = jsonString + "}"
            let docURL = URL(fileURLWithPath: outputPath)
            let dataPath = docURL.appendingPathComponent("Contents.json")
            try? jsonString.write(to: dataPath, atomically: true, encoding: .utf8)

        }
        
        func iOSJSON(_ array: [String]) -> String {
            var jsonString = ""
            for i in 0 ..< iosArray.count {
                let intValue = Int(iosArray[i])
                var sizeValue = intValue / iosScaleArray[i]
                if intValue == 166 {
                    sizeValue = 167 / iosScaleArray[i]
                }
                if jsonString.last == "}" {
                    jsonString = jsonString + ",\n"
                }
                jsonString = jsonString + "    {\n"
                if array[i] != "__nil__" {
                    jsonString = jsonString + "      \"filename\" : \"\(array[i])\",\n"
                }
                jsonString = jsonString + "      \"idiom\" : \"universal\",\n"
                jsonString = jsonString + "      \"platform\" : \"ios\",\n"
                if iosScaleArray[i] != 1 {
                    jsonString = jsonString + "      \"scale\" : \"\(iosScaleArray[i])x\",\n"
                }
                jsonString = jsonString + "      \"size\" : \"\(sizeValue)x\(sizeValue)\",\n"
                jsonString = jsonString + "    }"
                
            }
            return jsonString
        }
        
        func macOSJSON(_ array: [String]) -> String {
            var jsonString = ""
            for i in 0 ..< macosArray.count {
                let intValue = Int(macosArray[i])
                let sizeValue = intValue / macosScaleArray[i]
                if jsonString.last == "}" {
                    jsonString = jsonString + ",\n"
                }
                jsonString = jsonString + "    {\n"
                if array[i] != "__nil__" {
                    jsonString = jsonString + "      \"filename\" : \"\(array[i])\",\n"
                }
                jsonString = jsonString + "      \"idiom\" : \"mac\",\n"
                jsonString = jsonString + "      \"scale\" : \"\(macosScaleArray[i])x\",\n"
                jsonString = jsonString + "      \"size\" : \"\(sizeValue)x\(sizeValue)\",\n"
                jsonString = jsonString + "    }"
                
            }
            return jsonString
        }
        
        func watchOSJSON(_ array: [String]) -> String {
            var jsonString = ""
            for i in 0 ..< watchosArray.count {
                let intValue = Int(watchosArray[i])
                var sizeValue = intValue / watchosScaleArray[i]
                switch intValue {
                    case 54, 86:
                        let size = intValue + 1
                        sizeValue = size / watchosScaleArray[i]
                    default:
                        break
                }
                if jsonString.last == "}" {
                    jsonString = jsonString + ",\n"
                }
                jsonString = jsonString + "    {\n"
                if array[i] != "__nil__" {
                    jsonString = jsonString + "      \"filename\" : \"\(array[i])\",\n"
                }
                jsonString = jsonString + "      \"idiom\" : \"universal\",\n"
                jsonString = jsonString + "      \"platform\" : \"watchos\",\n"
                if watchosScaleArray[i] != 1 {
                    jsonString = jsonString + "      \"scale\" : \"\(watchosScaleArray[i])x\",\n"
                }
                jsonString = jsonString + "      \"size\" : \"\(sizeValue)x\(sizeValue)\",\n"
                jsonString = jsonString + "    }"
                
            }
            return jsonString
        }

    }
}

extension NSImage {
    func resized(to newSize: NSSize) -> NSImage? {
        if let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) {
            bitmapRep.size = newSize
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
            draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()

            let resizedImage = NSImage(size: newSize)
            resizedImage.addRepresentation(bitmapRep)
            return resizedImage
        }

        return nil
    }
    
    public func writePNG(toURL url: URL) {

            guard let data = tiffRepresentation,
                let rep = NSBitmapImageRep(data: data),
                let imgData = rep.representation(using: .png, properties: [.compressionFactor : NSNumber(floatLiteral: 1.0)]) else {

                    print("\(self.self) Error Function '\(#function)' Line: \(#line) No tiff rep found for image writing to \(url)")
                    return
            }

            do {
                try imgData.write(to: url)
            }catch let error {
                print("\(self.self) Error Function '\(#function)' Line: \(#line) \(error.localizedDescription)")
            }
        }
}
