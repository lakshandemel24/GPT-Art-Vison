import SwiftUI
import UIKit
import Combine
import InstantSearchVoiceOverlay

class SpeechData: ObservableObject {
    @Published var speechRequest: String = ""
}

// Declare a global variable to hold the touch point
var PaintingTouchPoint: CGPoint = .zero

struct PaintingView: View {
    
    @Binding var showPaintingView: Bool
    
    @ObservedObject var speechData = SpeechData()
    @State private var voiceOverlay: VoiceOverlayController = {
        let recordableHandler = {
            return SpeechController(locale: Locale(identifier: "it-IT"))
        }
        return VoiceOverlayController(speechControllerHandler: recordableHandler)
    }()
    
    @State private var displayedText: String = ""
    @State private var fullText: String = ""
    @State private var index: Int = 0
    @State private var timer: Timer?
    @State private var showSegmentationView = false
    
    @State private var masks: [(UIImage, String)] = []
    @State private var isLoading: Bool = false

    var body: some View {
        GeometryReader { geometry in
            VStack {
                //Richiesta -> speechData.speechRequest
                
                if let image = UIImage(named: currentPainting) {
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 400, height: 600)
                            .onAppear {
                                query(image: image) { output in
                                    if let output = output as? [[String: Any]] {
                                        var masksLabels : [String] = []
                                        for item in output {
                                            if let maskString = item["mask"] as? String,
                                               let label = item["label"] as? String,
                                               let maskData = Data(base64Encoded: maskString),
                                               let maskImage = UIImage(data: maskData) {
                                                let resizedMaskImage = resizeImage(image: maskImage, targetSize: CGSize(width: 400, height: 600))
                                                masks.append((resizedMaskImage, label))
                                                masksLabels.append(label)
                                            }
                                        }
                                        LoggingSystem.push(eventLog: ["event" : "Painting segmentation", "paintingName" : currentPainting, "detectedLabels" : masksLabels], verbose: false)
                                    } else {
                                        print("Failed to get response")
                                    }
                                }
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        let touchPoint = value.location
                                        PaintingTouchPoint = touchPoint
                                        SpeechManager.shared.stopSpeaking(immediately: true)
                                        for (mask, label) in masks {
                                            if isPointInWhiteArea(point: touchPoint, in: mask) {
                                                isLoading = true
                                                requestGPT(label) {
                                                    isLoading = false
                                                }
                                                break
                                            }
                                        }
                                    }
                            )
                        
                        if isLoading {
                            VStack {
                                ProgressView("Loading...")
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .frame(width: 100, height: 100)
                            }
                            .frame(width: 400, height: 600)
                        }
                    }
                } else {
                    Text("Image not found")
                }
                
                HStack {
                    
                    Button(action: {
                        SpeechManager.shared.stopSpeaking(immediately: false)
                        showPaintingView = false
                    }) {
                        Text("INDIETRO")
                            .font(.system(size: 20, weight: .bold))
                            .frame(width: 150, height: 50)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        SpeechManager.shared.stopSpeaking(immediately: true)
                        startVoiceRecognition()
                    }) {
                        Text("PARLA")
                            .font(.system(size: 20, weight: .bold))
                            .frame(width: 150, height: 50)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    
                }

            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    //messaggio indicazioni interfaccia...
                }
            }
            .background(Color.black)
        }
    }
    
    private func startVoiceRecognition() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            voiceOverlay.settings.autoStop = true
            voiceOverlay.start(on: rootViewController, textHandler: { text, final, _ in
                if final {
                    speechData.speechRequest = "\(speechData.speechRequest) in riferimento al dipinto '\(currentPainting)'"
                    //print(speechData.speechRequest)
                    gptRequest()
                    voiceOverlay.dismiss()
                } else {
                    speechData.speechRequest = text
                    voiceOverlay.dismiss()
                }
            }, errorHandler: { error in
                // Handle error
            })
        }
    }
    
    func gptRequest() {
        //print("Starting request...")
        
        // OpenAI API URL
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        // Your OpenAI API Key
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "No API Key Available in env"
        
        // Request Payload
        let parameters: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant."],
                ["role": "user", "content": speechData.speechRequest]
            ]
        ]
        
        // Convert parameters to JSON data
        let jsonData = try? JSONSerialization.data(withJSONObject: parameters)
        
        // Create a request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        // Create a URL session
        let session = URLSession.shared
        
        // Capture the start time
        let startTime = Date()
        
        // Make the request
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                SpeechManager.shared.stopSpeaking(immediately: true)
                SpeechManager.shared.speak(text: "Attualmente stiamo riscontrando problemi di rete...") {
                    
                }
                LoggingSystem.push(eventLog: ["event" : "Error", "details" : "GPT API Error: \(error?.localizedDescription ?? "Unknown error")"], verbose: false)
                return
            }
            
            // Calculate waiting time
            let waitingTime = Date().timeIntervalSince(startTime)
            
            // Parse the response
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String,
               let usage = json["usage"] as? [String: Any],
               let totalTokens = usage["total_tokens"] as? Int {
                //print("Message Content: \(content)")
                DispatchQueue.main.async {
                    fullText = content
                }
                SpeechManager.shared.speak(text: content) {
                    
                }
                print("Total Tokens Used: \(totalTokens)")
                LoggingSystem.push(eventLog: ["event" : "GPT request-response", "request" :  speechData.speechRequest, "response" : content, "tokens" : totalTokens, "model" : "gpt-4o", "paintingName" : currentPainting , "responseTime" : String(format: "%.2f", waitingTime)], verbose: false)
            } else {
                SpeechManager.shared.stopSpeaking(immediately: true)
                SpeechManager.shared.speak(text: "Attualmente stiamo riscontrando problemi di rete...") {
                    
                }
                print("Failed to parse response")
                LoggingSystem.push(eventLog: ["event" : "Error", "details" : "GPT failed to parse response"], verbose: false)
                return
            }
        }
        
        task.resume()
    }
    
    func query(image: UIImage, completion: @escaping (Any?) -> Void) {
        let apiUrl = URL(string: "https://api-inference.huggingface.co/models/mattmdjaga/segformer_b2_clothes")!
        let headers = ["Authorization": "Bearer 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"]
        
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            print("Failed to convert image to data")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = imageData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                SpeechManager.shared.stopSpeaking(immediately: true)
                SpeechManager.shared.speak(text: "Errore, torna indietro e riprova ad inquadrare il dipinto...") {
                    
                }
                // Print network-related error
                print("Network error: \(error.localizedDescription)")
                LoggingSystem.push(eventLog: ["event" : "Error", "details" : "HuggingFace API Network error: \(error.localizedDescription)"], verbose: false)
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                //print("HTTP Status Code: \(httpResponse.statusCode)")
                
                if !(200...299).contains(httpResponse.statusCode) {
                    SpeechManager.shared.stopSpeaking(immediately: true)
                    SpeechManager.shared.speak(text: "Errore, torna indietro e riprova ad inquadrare il dipinto...") {
                        
                    }
                    // Print server-side errors
                    print("Server error: HTTP Status Code \(httpResponse.statusCode)")
                    LoggingSystem.push(eventLog: ["event" : "Error", "details" : "HuggingFace API Server error: HTTP Status Code \(httpResponse.statusCode)"], verbose: false)
                    completion(nil)
                    return
                }
            }
            
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                completion(json)
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Determine the scale factor that preserves aspect ratio
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        // Create a graphics context and draw the image in it
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        let origin = CGPoint(
            x: (targetSize.width - scaledImageSize.width) / 2,
            y: (targetSize.height - scaledImageSize.height) / 2
        )
        image.draw(in: CGRect(origin: origin, size: scaledImageSize))
        
        // Get the new image from the context
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    func isPointInWhiteArea(point: CGPoint, in image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        let x = Int(point.x * width / 400)
        let y = Int(point.y * height / 600)
        
        guard x >= 0, x < Int(width), y >= 0, y < Int(height) else { return false }
        
        guard let pixelData = cgImage.dataProvider?.data else { return false }
        guard let data = CFDataGetBytePtr(pixelData) else { return false }
        
        let pixelInfo = ((Int(width) * y) + x) * 4
        
        guard pixelInfo + 2 < CFDataGetLength(pixelData) else { return false }
        
        let r = data[pixelInfo]
        let g = data[pixelInfo + 1]
        let b = data[pixelInfo + 2]
        
        return r == 255 && g == 255 && b == 255
    }
    
    func requestGPT(_ label: String, completion: @escaping () -> Void) {
        
        // OpenAI API URL
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "No API Key Available in env"
        
        // Request Payload
        let parameters: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant."],
                ["role": "user", "content": "Ho fato una segmentazione semantica in riferimento al dipinto \(currentPainting), forniscimi una brevissima spiegazione in riferimento all'etichetta \(label) (l'etichetta è in inglese traducimela in italiano). Non includere nella risposta le seguenti parole: etichetta, segmentazione. Comincia la frease dicendo: Stai toccando (articolo + nome dell'etichetta in italiano) che rappresenta..."]
            ]
        ]
        
        // Convert parameters to JSON data
        let jsonData = try? JSONSerialization.data(withJSONObject: parameters)
        
        // Create a request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        // Capture the start time
        let startTime = Date()
        
        // Create a URL session
        let session = URLSession.shared
        
        // Make the request
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                SpeechManager.shared.stopSpeaking(immediately: true)
                SpeechManager.shared.speak(text: "Attualmente stiamo riscontrando problemi di rete...") {
                    isLoading = false
                }
                return
            }
            
            // Calculate waiting time
            let waitingTime = Date().timeIntervalSince(startTime)
            
            // Parse the response
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String,
               let usage = json["usage"] as? [String: Any],
               let totalTokens = usage["total_tokens"] as? Int {
                SpeechManager.shared.speak(text: content) {
                    
                }
                completion()
                print("Total Tokens Used: \(totalTokens)")
                LoggingSystem.push(eventLog: ["event" : "GPT touch-response", "screenCoordinates" : ["pointX" : PaintingTouchPoint.x, "pointY" : PaintingTouchPoint.y], "touchedLabel" : label, "response" : content, "tokens" : totalTokens, "model" : "gpt-4o", "paintingName" : currentPainting , "responseTime" : String(format: "%.2f", waitingTime)], verbose: false)
            } else {
                print("Failed to parse response")
                SpeechManager.shared.stopSpeaking(immediately: true)
                SpeechManager.shared.speak(text: "Attualmente stiamo riscontrando problemi di rete...") {
                    isLoading = false
                }
                return
            }
        }
        
        task.resume()
        
    }
    
}
