import SwiftUI

struct PreferencesView: View {
    @AppStorage("theme") private var theme: String = "System"
    @AppStorage("quickFireTimer") private var quickFireTimer: Int = 30
    @AppStorage("defaultDifficulty") private var defaultDifficulty: Int = 1

    var body: some View {
        Form {
            Section(header: Text("Theme")) {
                Picker("Theme", selection: $theme) {
                    Text("System").tag("System")
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            Section(header: Text("Quick Fire Timer (seconds)")) {
                Stepper(value: $quickFireTimer, in: 3...10, step: 1) {
                    Text("\(quickFireTimer) seconds")
                }
            }
            Section(header: Text("Default Difficulty")) {
                Picker("Default Difficulty", selection: $defaultDifficulty) {
                    Text("Beginner").tag(1)
                    Text("Intermediate").tag(2)
                    Text("Advanced").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .navigationTitle("Preferences")
    }
}

#Preview {
    PreferencesView()
}
