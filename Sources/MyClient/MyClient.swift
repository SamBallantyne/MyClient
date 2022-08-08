import SwiftUI
import Foundation
import EventIdProvider

public struct ServerResponse<T : Codable> : Codable {
    public let success: Bool
    public let data: T?
    public let error: String?
}

public struct ShanghaiView<T : Codable> : Codable {
    public let application: String
    public let eventId: Int
    public let viewId: String
    public let evaluated: Bool
    public let failure: String?
    public let key: String?
    public let output: T?
}

public class ViewEndpointClient<T : Codable> : ObservableObject {
    
    public let _viewEndpointId: String
    public let _publishableKey: String
    public let _eventIdProvider: EventIdProvider
    
    @Published public var lastValue : ServerResponse<ShanghaiView<T>>? = nil
    @Published public var isLoadingEventId : Int? = nil
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
    
    public init(eventIdProvider: EventIdProvider, viewEndpointId: String, publishableKey: String) {
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
