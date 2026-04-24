//
//  QRCodeGenerator.swift
//  Sykle
//
//  Created by Sanuzia Jorge on 16/04/2026.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

/// Generate qr code images from strings

struct QRCodeGenerator {
    
    /// Generate a QR code image from a string
    /// - Parameters:
    ///   - string: The text to encode (e.g., "SYKLE-A7B3C9D2")
    ///   - size: The size of the output image
    /// - Returns: A UIImage of the QR code, or nil if generation fails
    static func generate(from string: String, size: CGFloat = 200) -> UIImage? {
        
        //create the QR code filter
        let filter = CIFilter.qrCodeGenerator()
        
        //set input data (the string to encode)
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        //set error correction level (h = high, cn recover 30% damage)
        filter.setValue("H", forKey: "InputCorrectionLevel")
        
        // get output CIImage
        guard let ciImage = filter.outputImage else {
            return nil
        }
        
        //scale up the image (small by default)
        let scale = size/ciImage.extent.width
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = ciImage.transformed(by: transform)
        
        //convert to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
        
    }
}

// MARK: - SwiftUI View Extension

// a swiftUI view that displays a qr code

struct QRCodeView: View {
    
    let code: String
    let size: CGFloat
    
    init(code: String, size: CGFloat = 200) {
        self.code = code
        self.size = size
        
    }
    
    var body: some View {
        
        if let uiImage = QRCodeGenerator.generate(from: code, size: size) {
            Image (uiImage: uiImage)
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
            
        } else {
            VStack {
                Image(systemName: "qrcode")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("Unable to generate QR Code")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: size, height: size)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        QRCodeView(code: "SYKLE-A7B3C9D2", size: 200)
        Text("SYKLE-A7B3C9D2")
            .font(.headline)
}

    
    
}
