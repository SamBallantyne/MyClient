import SwiftUI
import Foundation
import EventIdProvider

struct ServerResponse<T : Codable> : Codable {
    let success: Bool
    let data: T?
    let error: String?
}

struct ShanghaiView<T : Codable> : Codable {
    let application: String
    let eventId: Int
    let viewId: String
    let evaluated: Bool
    let failure: String?
    let key: String?
    let output: T?
}

class ViewEndpointClient<T : Codable> : ObservableObject {
    
    let _viewEndpointId: String
    let _publishableKey: String
    var _eventIdProvider: EventIdProvider
    
    @Published var lastValue : ServerResponse<ShanghaiView<T>>? = nil
    @Published var isLoadingEventId : Int? = nil
    var lastLoadedEventId: Int? = nil
    
    private func load (eventId: Int) {
        if (isLoadingEventId != nil) { return }
        self.isLoadingEventId = eventId;
        let url = URL(string: "https://backend.shanghai.technology/view-endpoints/\(_viewEndpointId)/view?eventId=\(eventId)")!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60.0)
        request.setValue("Bearer \(_publishableKey)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            self.isLoadingEventId = nil
            guard error == nil else {
                let error = error! as NSError
                print("task transport error \(error.domain) / \(error.code)")
                return
            }
            guard data != nil else {
                print("data was nil?")
                return
            }
            guard let parsed = try? JSONDecoder().decode(ServerResponse<ShanghaiView<T>>.self, from: data!) else {
                print("could not parse JSON: \(String(data: data!, encoding: .utf8)!)")
                return
            }
            print("Loaded view at offset \(eventId): \(parsed)")
            self.lastLoadedEventId = eventId
            self.lastValue = parsed
        }.resume()
    }
    
    init(eventIdProvider: EventIdProvider, viewEndpointId: String, publishableKey: String) {
        _eventIdProvider = eventIdProvider
        _viewEndpointId = viewEndpointId
        _publishableKey = publishableKey
        
        eventIdProvider.$eventId.sink { eventId in
            if (eventId != nil && (self.lastLoadedEventId == nil || eventId! > self.lastLoadedEventId!)) {
                self.load(eventId: eventId!)
            }
        }
    }
}
