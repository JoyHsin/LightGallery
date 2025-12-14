//
//  Notification+Extensions.swift
//  LightGallery
//
//  Created for authentication notifications
//

import Foundation

extension Notification.Name {
    /// 用户登录成功通知
    static let userDidLogin = Notification.Name("userDidLogin")
    
    /// 用户登出通知
    static let userDidLogout = Notification.Name("userDidLogout")
    
    /// 用户信息更新通知
    static let userProfileDidUpdate = Notification.Name("userProfileDidUpdate")
    
    /// 订阅状态更新通知
    static let subscriptionDidUpdate = Notification.Name("subscriptionDidUpdate")
    
    /// 显示付费墙通知
    static let showPaywall = Notification.Name("showPaywall")
    
    /// 订阅过期通知
    static let subscriptionExpired = Notification.Name("subscriptionExpired")
    
    /// 订阅需要登录通知
    static let loginRequiredForSubscription = Notification.Name("loginRequiredForSubscription")
    
    /// 功能访问需要登录通知
    static let loginRequiredForFeature = Notification.Name("loginRequiredForFeature")
}