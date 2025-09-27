import SwiftUI

struct ContentView: View {
    @ObservedObject var waterModel: WaterUsageModel
    
    var body: some View {
        TabView {
            // Main usage view
            UsageView(waterModel: waterModel)
            
            // History view
            HistoryView(waterModel: waterModel)
            
            // Quick actions view
            ActionsView(waterModel: waterModel)
        }
        .tabViewStyle(PageTabViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(waterModel: WaterUsageModel())
    }
}