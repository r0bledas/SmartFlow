//
//  AdBannerView.swift
//  SmartFlow
//
//  Created by Raudel Alejandro on 05-03-2026.
//

import SwiftUI
import GoogleMobileAds

struct AdBannerView: UIViewRepresentable {
    // Use test ads during development, production ads in release builds
    #if DEBUG
    private let adUnitID = "ca-app-pub-3940256099942544/2435281174" // Google test banner
    #else
    private let adUnitID = "ca-app-pub-2710889972191004/9703202683" // Production
    #endif
    
    func makeCoordinator() -> Coordinator {
        Coordinator(adUnitID: adUnitID)
    }
    
    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        
        let bannerView = BannerView()
        bannerView.adUnitID = adUnitID
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.delegate = context.coordinator
        context.coordinator.bannerView = bannerView
        
        container.addSubview(bannerView)
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            bannerView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        // Set root VC and size after a brief delay to ensure window is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                bannerView.rootViewController = rootVC
            }
            
            let viewWidth = UIScreen.main.bounds.width
            bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: viewWidth)
            
            // Load the ad
            bannerView.load(Request())
        }
        
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    // MARK: - Coordinator handles ad load failures & retries
    class Coordinator: NSObject, BannerViewDelegate {
        weak var bannerView: BannerView?
        private var retryCount = 0
        private let maxRetries = 5
        private let adUnitID: String
        
        init(adUnitID: String) {
            self.adUnitID = adUnitID
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("⚠️ Ad failed to load: \(error.localizedDescription)")
            
            // Retry with exponential backoff
            if retryCount < maxRetries {
                retryCount += 1
                let delay = pow(2.0, Double(retryCount))
                print("🔄 Retrying ad load in \(delay)s (attempt \(retryCount)/\(maxRetries))...")
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let banner = self?.bannerView else { return }
                    banner.load(Request())
                }
            }
        }
        
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("✅ Ad loaded successfully")
        }
    }
}
