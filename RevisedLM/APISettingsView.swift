import SwiftUI

struct APISettingsView: View {
    @AppStorage("apiMode") private var apiMode: String = "default"
    @AppStorage("openAIKey") private var openAIKey: String = ""
    @AppStorage("customEndpoint") private var customEndpoint: String = ""
    @AppStorage("customKey") private var customKey: String = ""

    var body: some View {
        Form {
            Section(header: Text("API Mode")) {
                Picker("API Mode", selection: $apiMode) {
                    Text("Default").tag("default")
                    Text("OpenAI").tag("openai")
                    Text("Custom").tag("custom")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            if apiMode == "openai" {
                Section(header: Text("OpenAI API Key")) {
                    SecureField("sk-...", text: $openAIKey)
                }
            } else if apiMode == "custom" {
                Section(header: Text("Custom Endpoint")) {
                    TextField("https://example.com/chat/completions", text: $customEndpoint)
                    SecureField("sk-...", text: $customKey)
                }
            }
        }
        .navigationTitle("API Settings")
    }
}

#Preview {
    APISettingsView()
}
