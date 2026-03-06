//
//  AdBannerView.swift
//  SmartFlow
//
//  Created by Raudel Alejandro on 05-03-2026.
//

import SwiftUI
import GoogleMobileAds

struct AdBannerView: UIViewRepresentable {
    // ⚠️ TEST AD UNIT ID — Replace with your real Ad Unit ID before App Store submission
    // Get your real ID from https://admob.google.com
    private let adUnitID = "ca-app-pub-3940256099942544/2435281174"
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView()
        bannerView.adUnitID = adUnitID
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Get the root view controller for ad presentation
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootVC
        }
        
        // Use adaptive banner size for full-width display
        let viewWidth = UIScreen.main.bounds.width
        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: viewWidth)
        
        // Load the ad
        bannerView.load(Request())
        
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        // No updates needed — the ad refreshes automatically
    }
}
