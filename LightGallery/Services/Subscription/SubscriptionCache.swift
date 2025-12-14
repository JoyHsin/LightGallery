//
//  SubscriptionCache.swift
//  LightGallery
//
//  Created for user-auth-subscription feature
//

import Foundation

class SubscriptionCache {
    private let userDefaults = UserDefaults.standard
    private let subscriptionKey = "cached_subscription"
    private let cacheTimestampKey = "subscription_cache_timestamp"
    private let cacheValidityDuration: TimeInterval = 24 * 60 * 60 // 24 hours
    
    /// Cache subscription status
    func cacheSubscription(_ subscription: Subscription) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(subscription)
            userDefaults.set(data, forKey: subscriptionKey)
            userDefaults.set(Date(), forKey: cacheTimestampKey)
        } catch {
            print("Failed to cache subscription: \(error)")
        }
    }
    
    /// Get cached subscription status
    func getCachedSubscription() -> Subscription? {
        guard let data = userDefaults.data(forKey: subscriptionKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let subscription = try decoder.decode(Subscription.self, from: data)
            return subscription
        } catch {
            print("Failed to decode cached subscription: \(error)")
            return nil
        }
    }
    
    /// Check if cache is valid (less than 24 hours old)
    func isCacheValid() -> Bool {
        guard let cacheTimestamp = userDefaults.object(forKey: cacheTimestampKey) as? Date else {
            return false
        }
        
        let now = Date()
        let timeSinceCache = now.timeIntervalSince(cacheTimestamp)
        return timeSinceCache < cacheValidityDuration
    }
    
    /// Get the age of the cache in seconds
    func getCacheAge() -> TimeInterval? {
        guard let cacheTimestamp = userDefaults.object(forKey: cacheTimestampKey) as? Date else {
            return nil
        }
        
        let now = Date()
        return now.timeIntervalSince(cacheTimestamp)
    }
    
    /// Check if cache exists
    func hasCachedSubscription() -> Bool {
        return userDefaults.data(forKey: subscriptionKey) != nil
    }
    
    /// Clear cache
    func clearCache() {
        userDefaults.removeObject(forKey: subscriptionKey)
        userDefaults.removeObject(forKey: cacheTimestampKey)
    }
}
