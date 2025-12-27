//
//  LocalizationManager.swift
//  Declutter
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI

enum Language: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        }
    }
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var language: Language {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
        }
    }
    
    private init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage")
        self.language = Language(rawValue: savedLanguage ?? "") ?? .english
    }
    
    func localized(_ key: String) -> String {
        switch language {
        case .english:
            return key
        case .simplifiedChinese:
            return simplifiedChinese[key] ?? key
        case .traditionalChinese:
            return traditionalChinese[key] ?? key
        }
    }
    
    // Dictionary for Simplified Chinese
    private let simplifiedChinese: [String: String] = [
        "Home": "首页",
        "Gallery": "相册",
        "Tools": "工具",
        "Settings": "设置",
        "Summary": "概览",
        "PHOTOS SIZE": "照片占用",
        "STORAGE SAVED": "已节省空间",
        "New": "新增",
        "this week": "本周",
        "Smart Clean": "智能清理",
        "Review items": "扫描清理",
        "Screenshots": "截图",
        "Duplicates": "重复照片",
        "Similar": "相似照片",
        "Find copies": "查找副本",
        "Review groups": "整理相册",
        "Preferences": "偏好设置",
        "Dark Mode": "深色模式",
        "Notifications": "通知",
        "Language": "语言",
        "About": "关于",
        "Version": "版本",
        "Privacy Policy": "隐私政策",
        "Terms of Service": "服务条款",
        "Support": "支持",
        "Help Center": "帮助中心",
        "Rate This App": "去评分",
        "Total Size to Clean": "可清理总大小",
        "All Clean!": "清理完毕！",
        "No items found to clean.": "没有发现需要清理的项目。",
        "Delete All": "全部删除",
        "Merge": "合并",
        "Merge All": "一键合并",
        "Select": "选择",
        "Done": "完成",
        "Cancel": "取消",
        "Delete": "删除",
        "Are you sure?": "确定吗？",
        "Used": "已使用",
        "Total": "总计",
        "Recommended": "推荐",
        "Coming Soon": "即将推出",
        "Soon": "敬请期待",
        "No Duplicates": "无重复照片",
        "Your library is free of duplicates.": "您的相册没有重复照片。",
        "Sets Found": "组重复照片",
        "Merge All Duplicates?": "合并所有重复照片？",
        "This will keep one version of each set and delete the rest. This action cannot be undone.": "这将保留每组中的一张照片并删除其余照片。此操作无法撤销。",
        "Scanning for duplicates...": "正在扫描重复照片...",
        "Loading screenshots...": "正在加载截图...",
        "No screenshots found": "没有发现截图",
        "Select All": "全选",
        "Deselect All": "取消全选",
        "Selected items": "已选项目",
        "Screenshot Cleanup": "截图清理",
        "Close": "关闭",
        "Scanning for similar photos...": "正在扫描相似照片...",
        "This may take a while depending on your library size": "这可能需要一点时间，取决于您的照片数量",
        "No similar photos found": "未发现相似照片",
        "Your library is clean!": "您的相册很整洁！",
        "To Delete": "待删除",
        "Space to free: Calculating...": "预计释放空间: 计算中...",
        "Delete Selected": "删除选中",
        "Similar Photo Cleanup": "相似照片清理",
        
        // Tools
        "Video Compressor": "视频压缩",
        "Reduce video file sizes": "减小视频体积",
        "Contacts Cleaner": "通讯录清理",
        "Merge duplicate contacts": "合并重复联系人",
        "Secret Space": "私密空间",
        "Hide private photos": "隐藏私密照片",
        "Photo Backup": "照片备份",
        "Export to Files app": "导出到文件应用",
        "AI Enhance": "AI 增强",
        "Upscale and improve photos": "提升画质与清晰度",
        
        // Settings & Other
        "Upgrade Plan": "升级套餐",
        "Expired Photos": "过期照片",
        "Low Quality": "低质量照片",
        "Finish": "结束",
        "Review Deletion": "确认删除",
        "Photos to Delete": "待删除照片",
        "Keep": "保留",
        "Review Complete": "审核完成",
        "photos marked for deletion": "张照片标记为删除",
        "No photos to delete": "没有要删除的照片",
        "You haven't swiped left on any photos yet.": "您还没有左滑删除任何照片。",
        "Review": "审核",
        "Expired Screenshots": "过期截图",
        
        // Watermark Remover
        "Watermark Remover": "去水印",
        "Download without watermark": "无水印下载",
        "Paste Link to Download": "粘贴链接下载",
        "Supports Instagram, TikTok, X, etc.": "支持小红书、抖音、微博、X 等",
        "Paste link here...": "在此粘贴链接...",
        "Download without Watermark": "无水印下载",
        "Supported Platforms": "支持平台",
        "Invalid URL": "无效链接",
        "Success": "成功",
        "Error": "错误",
        "OK": "确定",
        
        // Privacy Wiper
        "Privacy Wiper": "隐私抹除",
        "Remove location & device info": "移除位置和设备信息",
        "Select a Photo": "选择照片",
        "Choose Photo": "选择照片",
        "Change Photo": "更换照片",
        "Metadata Found:": "发现元数据：",
        "GPS:": "GPS位置：",
        "Device:": "拍摄设备：",
        "Contains Location": "包含位置信息",
        "Clean": "无位置信息",
        "Unknown": "未知",
        "Wipe & Save Copy": "抹除并保存副本",
        "Photo saved to Camera Roll without metadata.": "已保存无元数据的副本到相册。",
        
        // Live Photo Converter
        "Live Photo Converter": "实况照片转换",
        "Convert Live Photos to Video or GIF": "将实况照片转换为视频或GIF",
        "Select Live Photo": "选择实况照片",
        "Live Photo Selected": "已选择实况照片",
        "Save as Video": "保存为视频",
        "Save as GIF": "保存为GIF",
        "Video saved to Photos": "视频已保存到相册",
        "GIF saved to Photos": "GIF已保存到相册",
        
        // Stitcher
        "Stitcher": "长截图拼接",
        "Long Screenshot Stitcher": "长截图拼接",
        "Select overlapping screenshots": "选择重叠的截图",
        "Select Screenshots": "选择截图",
        "Change Selection": "更改选择",
        "Stitch Images": "拼接图片",
        "Stitched image saved to Photos": "拼接图片已保存到相册",
        "Combine screenshots": "合并截图",
        
        // Enhancer
        "AI Enhancer": "AI画质增强",
        "AI Photo Enhancer": "AI画质增强",
        "Upscale and restore photos": "放大并修复照片",
        "Upscale and restore": "放大并修复",
        "Enhancing...": "增强中...",
        "Before": "处理前",
        "After": "处理后",
        "Save Enhanced Photo": "保存增强照片",
        "Enhanced photo saved to Photos": "增强照片已保存到相册",
        
        // Converter
        "Format Converter": "格式转换",
        "Convert HEIC to JPEG/PNG": "HEIC转JPEG/PNG",
        "HEIC to JPEG/PNG": "HEIC转JPEG/PNG",
        "Output Format": "输出格式",
        "Format": "格式",
        "Quality": "质量",
        "Low": "低",
        "High": "高",
        "Selected Photos": "已选照片",
        "No photos selected": "未选择照片",
        "photos selected": "张照片已选择",
        "Select Photos": "选择照片",
        "Convert & Save": "转换并保存",
        "Converted photos saved to Camera Roll": "转换后的照片已保存到相册",
        
        // ID Photo Maker
        "ID Photo Maker": "智能证件照",
        "Smart ID Photo": "智能证件照",
        "Create compliant ID photos": "制作标准证件照",
        "Create Professional ID Photos": "制作专业证件照",
        "Automatically remove background, center face, and export compliant photos.": "自动去除背景、人脸居中，导出标准证件照。",
        "Choose from Library": "从相册选择",
        "Take Selfie": "拍摄自拍",
        "Analyzing...": "正在分析...",
        "Size": "尺寸",
        "Background Color": "背景颜色",
        "Retake": "重拍",
        "Save to Photos": "保存到相册",
        "Photo saved to Camera Roll.": "照片已保存到相册。",
        "Failed to process photo. Please try a clearer selfie.": "处理失败，请尝试拍摄更清晰的自拍。",
        "Failed to save photo.": "保存失败。",
        "Center your face in the oval": "请将面部对准椭圆框",
        "1 Inch": "1寸",
        "2 Inch": "2寸",
        "Passport": "护照",
        "White": "白色",
        "Blue": "蓝色",
        "Red": "红色",
        "Gray": "灰色",
        
        // Camera & Workflow
        "Reselect": "重选",
        "Use Photo": "使用照片",
        "Camera Access": "相机权限",
        "Camera is not available on this device.": "此设备上无法使用相机。",
        "Please enable camera access in Settings.": "请在设置中开启相机权限。",
        "Processing...": "处理中...",

        // Blurry Photos
        "Blurry": "模糊照片",
        "Blurry Photos": "模糊照片",
        "Out of focus": "对焦失败",
        "Analyzing photos...": "正在分析照片...",
        "This may take a moment": "这可能需要一点时间",
        "All Clear!": "全部清晰！",
        "No blurry photos found.": "没有发现模糊照片。",
        "blurry photos": "张模糊照片",
        "selected": "已选择",
        "Space to Free": "可释放空间",
        "Delete Blurry Photos?": "删除模糊照片？",
        "Very Blurry": "非常模糊",
        "Slightly Blurry": "轻微模糊",

        // Large Files
        "Large Files": "大文件",
        "Large photos and videos": "大照片和视频",
        "items": "项",
        "Scanning library...": "正在扫描相册..."
    ]
    
    // Dictionary for Traditional Chinese
    private let traditionalChinese: [String: String] = [
        "Home": "首頁",
        "Gallery": "相簿",
        "Tools": "工具",
        "Settings": "設定",
        "Summary": "概覽",
        "PHOTOS SIZE": "照片佔用",
        "STORAGE SAVED": "已節省空間",
        "New": "新增",
        "this week": "本週",
        "Smart Clean": "智能清理",
        "Review items": "掃描清理",
        "Screenshots": "截圖",
        "Duplicates": "重複照片",
        "Similar": "相似照片",
        "Find copies": "查找副本",
        "Review groups": "整理相簿",
        "Preferences": "偏好設定",
        "Dark Mode": "深色模式",
        "Notifications": "通知",
        "Language": "語言",
        "About": "關於",
        "Version": "版本",
        "Privacy Policy": "隱私政策",
        "Terms of Service": "服務條款",
        "Support": "支援",
        "Help Center": "幫助中心",
        "Rate This App": "去評分",
        "Total Size to Clean": "可清理總大小",
        "All Clean!": "清理完畢！",
        "No items found to clean.": "沒有發現需要清理的項目。",
        "Delete All": "全部刪除",
        "Merge": "合併",
        "Merge All": "一鍵合併",
        "Select": "選擇",
        "Done": "完成",
        "Cancel": "取消",
        "Delete": "刪除",
        "Are you sure?": "確定嗎？",
        "Used": "已使用",
        "Total": "總計",
        "Recommended": "推薦",
        "Coming Soon": "即將推出",
        "Soon": "敬請期待",
        "No Duplicates": "無重複照片",
        "Your library is free of duplicates.": "您的相簿沒有重複照片。",
        "Sets Found": "組重複照片",
        "Merge All Duplicates?": "合併所有重複照片？",
        "This will keep one version of each set and delete the rest. This action cannot be undone.": "這將保留每組中的一張照片並刪除其餘照片。此操作無法撤銷。",
        "Scanning for duplicates...": "正在掃描重複照片...",
        "Loading screenshots...": "正在加載截圖...",
        "No screenshots found": "沒有發現截圖",
        "Select All": "全選",
        "Deselect All": "取消全選",
        "Selected items": "已選項目",
        "Screenshot Cleanup": "截圖清理",
        "Close": "關閉",
        "Scanning for similar photos...": "正在掃描相似照片...",
        "This may take a while depending on your library size": "這可能需要一點時間，取決於您的照片數量",
        "No similar photos found": "未發現相似照片",
        "Your library is clean!": "您的相簿很整潔！",
        "To Delete": "待刪除",
        "Space to free: Calculating...": "預計釋放空間: 計算中...",
        "Delete Selected": "刪除選中",
        "Similar Photo Cleanup": "相似照片清理",
        
        // Tools
        "Video Compressor": "影片壓縮",
        "Reduce video file sizes": "減小影片體積",
        "Contacts Cleaner": "通訊錄清理",
        "Merge duplicate contacts": "合併重複聯絡人",
        "Secret Space": "私密空間",
        "Hide private photos": "隱藏私密照片",
        "Photo Backup": "照片備份",
        "Export to Files app": "導出到檔案應用",
        "AI Enhance": "AI 增強",
        "Upscale and improve photos": "提升畫質與清晰度",
        
        // Settings & Other
        "Upgrade Plan": "升級方案",
        "Expired Photos": "過期照片",
        "Low Quality": "低質量照片",
        "Finish": "結束",
        "Review Deletion": "確認刪除",
        "Photos to Delete": "待刪除照片",
        "Keep": "保留",
        "Review Complete": "審核完成",
        "photos marked for deletion": "張照片標記為刪除",
        "No photos to delete": "沒有要刪除的照片",
        "You haven't swiped left on any photos yet.": "您還沒有左滑刪除任何照片。",
        "Review": "審核",
        "Expired Screenshots": "過期截圖",
        
        // Watermark Remover
        "Watermark Remover": "去水印",
        "Download without watermark": "無水印下載",
        "Paste Link to Download": "貼上連結下載",
        "Supports Instagram, TikTok, X, etc.": "支持小紅書、抖音、微博、X 等",
        "Paste link here...": "在此貼上連結...",
        "Download without Watermark": "無水印下載",
        "Supported Platforms": "支持平台",
        "Invalid URL": "無效連結",
        "Success": "成功",
        "Error": "錯誤",
        "OK": "確定",
        
        // Privacy Wiper
        "Privacy Wiper": "隱私抹除",
        "Remove location & device info": "移除位置和設備信息",
        "Select a Photo": "選擇照片",
        "Choose Photo": "選擇照片",
        "Change Photo": "更換照片",
        "Metadata Found:": "發現元數據：",
        "GPS:": "GPS位置：",
        "Device:": "拍攝設備：",
        "Contains Location": "包含位置信息",
        "Clean": "無位置信息",
        "Unknown": "未知",
        "Wipe & Save Copy": "抹除並保存副本",
        "Photo saved to Camera Roll without metadata.": "已保存無元數據的副本到相簿。",
        
        // Live Photo Converter
        "Live Photo Converter": "實況照片轉換",
        "Convert Live Photos to Video or GIF": "將實況照片轉換為影片或GIF",
        "Select Live Photo": "選擇實況照片",
        "Live Photo Selected": "已選擇實況照片",
        "Save as Video": "保存為影片",
        "Save as GIF": "保存為GIF",
        "Video saved to Photos": "影片已保存到相簿",
        "GIF saved to Photos": "GIF已保存到相簿",
        
        // Stitcher
        "Stitcher": "長截圖拼接",
        "Long Screenshot Stitcher": "長截圖拼接",
        "Select overlapping screenshots": "選擇重疊的截圖",
        "Select Screenshots": "選擇截圖",
        "Change Selection": "更改選擇",
        "Stitch Images": "拼接圖片",
        "Stitched image saved to Photos": "拼接圖片已保存到相簿",
        "Combine screenshots": "合併截圖",
        
        // Enhancer
        "AI Enhancer": "AI畫質增強",
        "AI Photo Enhancer": "AI畫質增強",
        "Upscale and restore photos": "放大並修復照片",
        "Upscale and restore": "放大並修復",
        "Enhancing...": "增強中...",
        "Before": "處理前",
        "After": "處理後",
        "Save Enhanced Photo": "保存增強照片",
        "Enhanced photo saved to Photos": "增強照片已保存到相簿",
        
        // Converter
        "Format Converter": "格式轉換",
        "Convert HEIC to JPEG/PNG": "HEIC轉JPEG/PNG",
        "HEIC to JPEG/PNG": "HEIC轉JPEG/PNG",
        "Output Format": "輸出格式",
        "Format": "格式",
        "Quality": "質量",
        "Low": "低",
        "High": "高",
        "Selected Photos": "已選照片",
        "No photos selected": "未選擇照片",
        "photos selected": "張照片已選擇",
        "Select Photos": "選擇照片",
        "Convert & Save": "轉換並保存",
        "Converted photos saved to Camera Roll": "轉換後的照片已保存到相簿",
        
        // ID Photo Maker
        "ID Photo Maker": "智能證件照",
        "Smart ID Photo": "智能證件照",
        "Create compliant ID photos": "製作標準證件照",
        "Create Professional ID Photos": "製作專業證件照",
        "Automatically remove background, center face, and export compliant photos.": "自動去除背景、人臉居中，導出標準證件照。",
        "Choose from Library": "從相簿選擇",
        "Take Selfie": "拍攝自拍",
        "Analyzing...": "正在分析...",
        "Size": "尺寸",
        "Background Color": "背景顏色",
        "Retake": "重拍",
        "Save to Photos": "保存到相簿",
        "Photo saved to Camera Roll.": "照片已保存到相簿。",
        "Failed to process photo. Please try a clearer selfie.": "處理失敗，請嘗試拍攝更清晰的自拍。",
        "Failed to save photo.": "保存失敗。",
        "Center your face in the oval": "請將面部對準橢圓框",
        "1 Inch": "1寸",
        "2 Inch": "2寸",
        "Passport": "護照",
        "White": "白色",
        "Blue": "藍色",
        "Red": "紅色",
        "Gray": "灰色",
        
        // Camera & Workflow
        "Reselect": "重選",
        "Use Photo": "使用照片",
        "Camera Access": "相機權限",
        "Camera is not available on this device.": "此設備上無法使用相機。",
        "Please enable camera access in Settings.": "請在設定中開啟相機權限。",
        "Processing...": "處理中...",

        // Blurry Photos
        "Blurry": "模糊照片",
        "Blurry Photos": "模糊照片",
        "Out of focus": "對焦失敗",
        "Analyzing photos...": "正在分析照片...",
        "This may take a moment": "這可能需要一點時間",
        "All Clear!": "全部清晰！",
        "No blurry photos found.": "沒有發現模糊照片。",
        "blurry photos": "張模糊照片",
        "selected": "已選擇",
        "Space to Free": "可釋放空間",
        "Delete Blurry Photos?": "刪除模糊照片？",
        "Very Blurry": "非常模糊",
        "Slightly Blurry": "輕微模糊",

        // Large Files
        "Large Files": "大檔案",
        "Large photos and videos": "大照片和影片",
        "items": "項",
        "Scanning library...": "正在掃描相簿..."
    ]
}

// Helper extension for easy usage
extension String {
    var localized: String {
        LocalizationManager.shared.localized(self)
    }
}
