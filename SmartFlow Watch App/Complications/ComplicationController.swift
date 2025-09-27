//
//  ComplicationController.swift
//  SmartFlow Watch App
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import ClockKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {
    // Time when complications were last updated
    private var lastUpdateTime: Date?
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, 
                                          withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        // Time travel not supported
        handler([])
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, 
                            withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Show complication data on lock screen
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, 
                                 withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Get the shared model data from the watch app
        guard let waterModel = getWaterModel() else {
            handler(nil)
            return
        }
        
        // Create a template based on the complication family
        if let template = createTemplate(for: complication.family, with: waterModel) {
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)
        } else {
            handler(nil)
        }
    }
    
    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, 
                                      withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // Create a sample template
        let sampleModel = createSampleModel()
        let template = createTemplate(for: complication.family, with: sampleModel)
        handler(template)
    }
    
    // MARK: - Helper Methods
    
    private func getWaterModel() -> WatchWaterUsageModel? {
        // Try to get the shared instance of the model
        // In a real app, this would access shared app data
        guard let appDelegate = WKExtension.shared().delegate as? ExtensionDelegate else {
            return createSampleModel()
        }
        
        return appDelegate.waterModel
    }
    
    private func createSampleModel() -> WatchWaterUsageModel {
        let model = WatchWaterUsageModel()
        model.currentUsage = 75.0
        model.usageLimit = 100.0
        model.unit = "L"
        return model
    }
    
    private func createTemplate(for family: CLKComplicationFamily, with model: WatchWaterUsageModel) -> CLKComplicationTemplate? {
        // Calculate the percentage used
        let percentUsed = Int(model.percentUsed * 100)
        let usageText = "\(Int(model.currentUsage))/\(Int(model.usageLimit))"
        
        switch family {
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallRingText()
            template.textProvider = CLKSimpleTextProvider(text: "\(percentUsed)%")
            template.fillFraction = Float(model.percentUsed)
            template.ringStyle = .closed
            
            // Set ring color based on usage level
            if model.percentUsed < 0.8 {
                template.tintColor = .blue
            } else if model.percentUsed < 1.0 {
                template.tintColor = .orange
            } else {
                template.tintColor = .red
            }
            
            return template
            
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallRingText()
            template.textProvider = CLKSimpleTextProvider(text: "\(percentUsed)")
            template.fillFraction = Float(model.percentUsed)
            template.ringStyle = .closed
            
            if model.percentUsed < 0.8 {
                template.tintColor = .blue
            } else if model.percentUsed < 1.0 {
                template.tintColor = .orange
            } else {
                template.tintColor = .red
            }
            
            return template
            
        case .modularLarge:
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "SmartFlow")
            template.body1TextProvider = CLKSimpleTextProvider(text: "Water Usage: \(percentUsed)%")
            template.body2TextProvider = CLKSimpleTextProvider(text: usageText + " " + model.unit)
            return template
            
        case .utilitarianSmall:
            let template = CLKComplicationTemplateUtilitarianSmallRingText()
            template.textProvider = CLKSimpleTextProvider(text: "\(percentUsed)")
            template.fillFraction = Float(model.percentUsed)
            template.ringStyle = .closed
            
            if model.percentUsed < 0.8 {
                template.tintColor = .blue
            } else if model.percentUsed < 1.0 {
                template.tintColor = .orange
            } else {
                template.tintColor = .red
            }
            
            return template
            
        case .graphicCorner:
            let template = CLKComplicationTemplateGraphicCornerGaugeText()
            template.gaugeProvider = CLKSimpleGaugeProvider(
                style: .fill,
                gaugeColor: model.usageColor,
                fillFraction: Float(model.percentUsed)
            )
            template.outerTextProvider = CLKSimpleTextProvider(text: "\(Int(model.currentUsage))")
            template.leadingTextProvider = CLKSimpleTextProvider(text: "💧")
            return template
            
        default:
            return nil
        }
    }
}

// Extension Delegate to access the shared model
class ExtensionDelegate: NSObject, WKExtensionDelegate {
    let waterModel = WatchWaterUsageModel()
    
    func applicationDidFinishLaunching() {
        // Initialize the app
    }
}