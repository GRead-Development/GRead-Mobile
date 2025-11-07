import Foundation

class APIManager {
    static let shared = APIManager()
    private let baseURL = "https://gread.fun/wp-json/buddypress/v1"
    private let customBaseURL = "https://gread.fun/wp-json/gread/v1"
    
    private init() {}
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add JWT token to Authorization header
        if authenticated, let token = AuthManager.shared.jwtToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Print response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("API Response [\(endpoint)]: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("API Error: Status \(httpResponse.statusCode)")
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        // Check if response is "false" (boolean) - common for empty results
        if let responseString = String(data: data, encoding: .utf8),
           responseString.trimmingCharacters(in: .whitespacesAndNewlines) == "false" {
            // For array types, return empty array
            if T.self is [Any].Type {
                return [] as! T
            }
            throw APIError.emptyResponse
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding error for \(endpoint): \(error)")
            
            // If decoding fails and we're expecting an array, try returning empty
            if T.self is [Any].Type {
                return [] as! T
            }
            
            throw APIError.decodingError(error)
        }
    }
    
    // Custom API request for GRead endpoints
    func customRequest<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        guard let url = URL(string: customBaseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add JWT token to Authorization header
        if authenticated, let token = AuthManager.shared.jwtToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Print response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Custom API Response [\(endpoint)]: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("Custom API Error: Status \(httpResponse.statusCode)")
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(T.self, from: data)
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case emptyResponse
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .emptyResponse:
            return "No data available"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
