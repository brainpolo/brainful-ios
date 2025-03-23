/**
 Author(s): Aditya Dedhia
 copyright 2022-2025 brainful
 */

import Foundation
import Network
import SwiftUI
import SystemConfiguration.CaptiveNetwork


let api = brainfulAPI()  // For use across app


var api_key: String = ""

var latitude: String?
var longitude: String?

func initializeLocation() {
    let locationManager = brainfulLocationManager()
    locationManager.getCurrentLocation { lat, long in
        latitude = String(lat)
        longitude = String(long)
        print("Latitude: \(latitude ?? ""), Longitude: \(longitude ?? "")")
    }
}


class brainfulAPI {
    let domain = ProcessInfo.processInfo.environment["DOMAIN"] ?? "https://brainful.ai"
    private var headers: [String: String] {
        [
            "Content-Type": "application/json",
            "Authorization": "Token \(api_key)",
        ]
    }
    
    func registerUser(firstName: String, lastName: String, email: String, username: String, password: String) async throws {
        
        let url = URL(string: "\(domain)/api/register")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }
        
        let platform: String
        if isIPad() {
            platform = "ipad"
        } else {
            platform = "ios"
        }
        
        let registrationData: [String: Any] = [
            "first_name": firstName,
            "last_name": lastName,
            "email": email,
            "username": username,
            "password": password,
            "platform": platform
        ]
        print("registration called")
        
        let jsonData = try JSONSerialization.data(withJSONObject: registrationData)
        urlRequest.httpBody = jsonData
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        if let responseJson = try? decoder.decode([String: String].self, from: data), let token = responseJson["token"] {
            print("User token: \(token)")
            api_key = token // Store token in session
            // Upon successful auth, update account username in appState
            AppState.shared.username = username
            do {
                try KeychainManager.savePassword(
                    attribute: "auth",
                    username: username,
                    password: password.data(using: .utf8) ?? Data()
                )
            } catch {
                print(error)
            }
            isAuthenticated = true // Send message to brainfulApp button to invoke the contentview states
        }
    }
    
    func loginUser(username: String, password: String) async throws {
        let url = URL(string: "\(domain)/users/api/login")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let platform: String
        if isIPad() {
            platform = "ipad"
        } else {
            platform = "ios"
        }
        let agent: String = get_agent() ?? ""
        print(agent)

        let loginData: [String: Any] = [
            "username": username,
            "password": password,
            // Additional Auth Fields
            "platform": platform,
            "agent": agent
        ]

        let formBody = loginData.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        urlRequest.httpBody = formBody.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let responseData = String(data: data, encoding: .utf8) {
                    print("API response data: \(responseData)")
                }
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        if let responseJson = try? decoder.decode([String: String].self, from: data), let token = responseJson["token"] {
            print("User token: \(token)")
            api_key = token // Store token in session
            // Upon successful auth, update account username
            AppState.shared.username = username
            do {
                try KeychainManager.savePassword(
                    attribute: "auth",
                    username: username,
                    password: password.data(using: .utf8) ?? Data()
                )
            } catch {
                print(error)
            }
            initializeLocation() // For geo node data
            isAuthenticated = true // Send message to brainfulApp button to invoke the contentview states
        }
    }

    func add_block(string: String? = nil, fileURL: URL? = nil) async throws -> Block {
        let url = URL(string: "\(domain)/my/blocks/add")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }
        
        if let fileURL = fileURL {
            let boundary = UUID().uuidString
            urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            let httpBody = try createMultipartFormData(boundary: boundary, text: string, fileURL: fileURL)
            urlRequest.httpBody = httpBody
        } else {
            let parameters: [String: Any] = [
                "string": string ?? "",
                "latitude": latitude ?? "",
                "longitude": longitude ?? "",
                "agent": get_agent() ?? ""
            ]
            
            let parameterData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            urlRequest.httpBody = parameterData
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (responseData, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw APIError.invalidResponse
        }
        // 1. Attempt to decode the response into an array of Block objects
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter) // Use custom date formatter for decoding
        
        do {
            let b = try decoder.decode(Block.self, from: responseData)
            return b
        } catch {
            print("Error decoding response: \(error)")
            throw APIError.invalidResponse
        }
        
    }


    func createMultipartFormData(boundary: String, text: String?, fileURL: URL) throws -> Data {
        var httpBody = Data()
        
        let fileData = try Data(contentsOf: fileURL)
        
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        httpBody.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        httpBody.append(fileData)
        httpBody.append("\r\n".data(using: .utf8)!)
        
        if let text = text {
            httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
            httpBody.append("Content-Disposition: form-data; name=\"text\"\r\n\r\n".data(using: .utf8)!)
            httpBody.append("\(text)\r\n".data(using: .utf8)!)
        }
        
        httpBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return httpBody
    }
    
    
    // Helper models and functions
    struct BlockHash: Codable {
        let luid: String
        let hash: String
    }
    
    struct BlockSyncStatus {
        let totalCount: Int
        let updatedCount: Int
        let isInitialSync: Bool
        
        var message: String {
            if updatedCount == 0 {
                return "Already up to date (\(totalCount) blocks)"
            } else if isInitialSync {
                return "Initial sync completed (\(totalCount) blocks)"
            } else {
                return "Updated \(updatedCount) of \(totalCount) blocks"
            }
        }
    }

    func get_blocks() async throws -> (blocks: [Block], status: BlockSyncStatus) {
        // Check stored hashes
        let storedHashes = UserDefaults.standard.dictionary(forKey: "blockHashes") as? [String: String] ?? [:]
        print("📊 Stored hashes count: \(storedHashes.count)")
        
        // Fetch hashes from server
        print("🌐 Fetching block hashes from server...")
        let blockHashesURLEndpoint = URL(string: "\(domain)/my/blocks/get/hashes")
        var blockHashRequest = URLRequest(url: blockHashesURLEndpoint!)
        blockHashRequest.httpMethod = "GET"
        
        headers.forEach { blockHashRequest.setValue($1, forHTTPHeaderField: $0) }
        
        let (data, response) = try await URLSession.shared.data(for: blockHashRequest)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Parse the server hashes
        let serverHashesResponse = try JSONDecoder().decode([BlockHash].self, from: data)
        let serverHashes = Dictionary(uniqueKeysWithValues:
            serverHashesResponse.map { ($0.luid, $0.hash) })
        print("📊 Server hashes count: \(serverHashes.count)")
        
        // Find blocks that need updating
        let luidsToFetch = serverHashes.compactMap { luid, hash in
            return storedHashes[luid] != hash ? luid : nil
        }
        print("🔄 Blocks to fetch: \(luidsToFetch.count) of \(serverHashes.count) total")
        
        // Create sync status
        let isInitialSync = (storedHashes.count == 0)
        let syncStatus = BlockSyncStatus(
            totalCount: serverHashes.count,
            updatedCount: luidsToFetch.count,
            isInitialSync: isInitialSync
        )
        
        // If no blocks need fetching, return early with existing blocks
        if luidsToFetch.isEmpty {
            print("✅ No blocks need updating - using cached data")
            return (blocks: BlockManager.shared.getAllBlocks(), status: syncStatus)
        }
        // Create request for blocks
        let url = URL(string: "\(domain)/my/blocks/get")!
        var urlRequest = URLRequest(url: url)
        
        // Set Content-Type header for JSON
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Determine whether to GET or POST
        if (luidsToFetch.count == serverHashes.keys.count) {
            print("⬇️ Fetching all blocks (initial sync)")
            urlRequest.httpMethod = "GET"
        } else {
            print("⬇️ Fetching \(luidsToFetch.count) updated blocks")
            urlRequest.httpMethod = "POST"
            let requestBody = ["block_luids": luidsToFetch]
            urlRequest.httpBody = try JSONEncoder().encode(requestBody)
            
            // Debug the JSON payload
            if let jsonStr = String(data: urlRequest.httpBody!, encoding: .utf8) {
                print("📦 Request body: \(jsonStr)")
            }
        }

        // Append default headers
        headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }

        do {
            print("🌐 Sending request to fetch blocks...")
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("❌ Server returned error status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
            }

            print("✅ Received response from server")
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)

                // Try standard ISO8601 format
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                if let date = isoFormatter.date(from: dateString) {
                    return date
                }

                // Fallback: Try removing milliseconds if necessary
                let trimmedString = dateString.components(separatedBy: ".").first ?? dateString
                if let fallbackDate = isoFormatter.date(from: trimmedString + "Z") {
                    return fallbackDate
                }

                // If all parsing fails, return nil
                return Date() as Date
            }

            do {
                let updated_blocks = try decoder.decode([Block].self, from: data)
                print("📦 Successfully decoded \(updated_blocks.count) blocks from response")
                
                // Save the blocks to CoreData
                print("💾 Saving blocks to Core Data...")
                BlockManager.shared.saveBlocks(updated_blocks)
                
                // Update stored hashes
                print("💾 Updating hash storage in UserDefaults with \(serverHashes.count) hashes")
                UserDefaults.standard.set(serverHashes, forKey: "blockHashes")
                
                // Force immediate write to storage
                UserDefaults.standard.synchronize()
                
                // Verify hashes were saved
                let verifyHashes = UserDefaults.standard.dictionary(forKey: "blockHashes") as? [String: String] ?? [:]
                print("✅ Verification: \(verifyHashes.count) hashes now in UserDefaults")
                
                // Return all blocks from Core Data
                print("🔄 Retrieving all blocks from Core Data")
                return (blocks: BlockManager.shared.getAllBlocks(), status: syncStatus)
            } catch {
                print("❌ JSON Decoding Error: \(error)")
                throw APIError.invalidResponse
            }
        } catch {
            print("❌ Network Request Failed: \(error.localizedDescription)")
            throw APIError.httpError(500)
        }
    }
    
    func get_block(block_luid: String) async throws -> Block {
        let url = URL(string: "\(domain)/my/blocks/get/\(block_luid)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                throw APIError.httpError(httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)

                // Try standard ISO8601 format
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                if let date = isoFormatter.date(from: dateString) {
                    return date
                }

                // Fallback: Try removing milliseconds if necessary
                let trimmedString = dateString.components(separatedBy: ".").first ?? dateString
                if let fallbackDate = isoFormatter.date(from: trimmedString + "Z") {
                    return fallbackDate
                }

                // If all parsing fails, return current date
                return Date()
            }

            let block = try decoder.decode(Block.self, from: data)
            return block
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            throw APIError.invalidResponse
        } catch {
            print("Error fetching block: \(error)")
            throw error
        }
    }

}
// Define a DateFormatter for ISO 8601
let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ" // Match server's date format
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()
enum APIError: Error {
    case httpError(Int)
    case invalidResponse
    case fileAccessDenied
    case invalidData
}
