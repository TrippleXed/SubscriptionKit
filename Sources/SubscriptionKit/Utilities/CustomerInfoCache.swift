import Foundation

/// Caches CustomerInfo to disk for offline access
final class CustomerInfoCache: Sendable {

    private let cacheKey = "com.subscriptionkit.customerinfo"
    private let cacheExpiryKey = "com.subscriptionkit.customerinfo.expiry"

    /// Cache duration in seconds (default: 5 minutes)
    private let cacheDuration: TimeInterval = 5 * 60

    /// Load cached customer info if still valid
    func load() -> CustomerInfo? {
        guard let expiryDate = UserDefaults.standard.object(forKey: cacheExpiryKey) as? Date,
              expiryDate > Date() else {
            return nil
        }

        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(CustomerInfo.self, from: data)
        } catch {
            Logger.warning("Failed to decode cached customer info: \(error)")
            return nil
        }
    }

    /// Save customer info to cache
    func save(_ customerInfo: CustomerInfo) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(customerInfo)

            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date().addingTimeInterval(cacheDuration), forKey: cacheExpiryKey)
        } catch {
            Logger.warning("Failed to cache customer info: \(error)")
        }
    }

    /// Clear the cache
    func clear() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheExpiryKey)
    }
}
