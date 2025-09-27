import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Complication Configuration
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "complication", displayName: "SmartFlow", supportedFamilies: [.circularSmall, .graphicCircular, .graphicCorner, .graphicBezel])
        ]
        
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }
    
    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
        handler(Date().addingTimeInterval(24 * 60 * 60)) // 24 hours from now
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Get the shared model to access the current water usage
        guard let model = getSharedWaterModel() else {
            handler(nil)
            return
        }
        
        // Create a template based on the complication's family
        var template: CLKComplicationTemplate?
        
        switch complication.family {
        case .circularSmall:
            let smallTemplate = CLKComplicationTemplateCircularSmallRingText()
            smallTemplate.textProvider = CLKSimpleTextProvider(text: "\(Int(model.currentUsage))")
            
            let percentage = model.currentUsage / model.usageLimit
            smallTemplate.fillFraction = Float(min(percentage, 1.0))
            
            // Color based on usage level
            if percentage >= 1.0 {
                smallTemplate.ringStyle = .closed
                smallTemplate.tintColor = .red
            } else if percentage >= 0.8 {
                smallTemplate.ringStyle = .closed
                smallTemplate.tintColor = .orange
            } else {
                smallTemplate.ringStyle = .closed
                smallTemplate.tintColor = .blue
            }
            
            template = smallTemplate
            
        case .graphicCircular:
            let circularTemplate = CLKComplicationTemplateGraphicCircularClosedGaugeText()
            circularTemplate.gaugeProvider = CLKSimpleGaugeProvider(
                style: .fill,
                gaugeColor: model.currentUsage >= model.usageLimit ? .red : 
                           model.currentUsage >= 0.8 * model.usageLimit ? .orange : .blue,
                fillFraction: Float(min(model.currentUsage / model.usageLimit, 1.0))
            )
            circularTemplate.centerTextProvider = CLKSimpleTextProvider(text: "\(Int(model.currentUsage))")
            
            template = circularTemplate
            
        case .graphicCorner:
            let cornerTemplate = CLKComplicationTemplateGraphicCornerGaugeText()
            cornerTemplate.gaugeProvider = CLKSimpleGaugeProvider(
                style: .fill,
                gaugeColor: model.currentUsage >= model.usageLimit ? .red : 
                           model.currentUsage >= 0.8 * model.usageLimit ? .orange : .blue,
                fillFraction: Float(min(model.currentUsage / model.usageLimit, 1.0))
            )
            cornerTemplate.leadingTextProvider = CLKSimpleTextProvider(text: "💧")
            cornerTemplate.trailingTextProvider = CLKSimpleTextProvider(text: "\(Int(model.currentUsage))")
            
            template = cornerTemplate
            
        case .graphicBezel:
            let circularTemplate = CLKComplicationTemplateGraphicCircularClosedGaugeText()
            circularTemplate.gaugeProvider = CLKSimpleGaugeProvider(
                style: .fill,
                gaugeColor: model.currentUsage >= model.usageLimit ? .red : 
                           model.currentUsage >= 0.8 * model.usageLimit ? .orange : .blue,
                fillFraction: Float(min(model.currentUsage / model.usageLimit, 1.0))
            )
            circularTemplate.centerTextProvider = CLKSimpleTextProvider(text: "\(Int(model.currentUsage))")
            
            let bezelTemplate = CLKComplicationTemplateGraphicBezelCircularText()
            bezelTemplate.circularTemplate = circularTemplate
            bezelTemplate.textProvider = CLKSimpleTextProvider(
                text: "SmartFlow: \(Int(model.currentUsage))/\(Int(model.usageLimit)) \(model.unit)"
            )
            
            template = bezelTemplate
            
        default:
            // Other complication families are not supported
            handler(nil)
            return
        }
        
        // Make sure a template was created
        guard let template = template else {
            handler(nil)
            return
        }
        
        // Create the timeline entry
        let timelineEntry = CLKComplicationTimelineEntry(
            date: Date(),
            complicationTemplate: template
        )
        
        // Call the handler with the current timeline entry
        handler(timelineEntry)
    }
    
    // MARK: - Helper Methods
    
    private func getSharedWaterModel() -> WaterUsageModel? {
        // In a real app, you would retrieve the model from a shared data source
        // For this demo, we'll create a new instance with some sample data
        let model = WaterUsageModel()
        return model
    }
}