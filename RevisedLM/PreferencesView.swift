import SwiftUI

struct PreferencesView: View {
  @AppStorage("theme") private var theme: String = "System"
  @AppStorage("quickFireTimer") private var quickFireTimer: Int = 30
  @AppStorage("defaultDifficulty") private var defaultDifficulty: Int = 1
  @AppStorage("personalDetails") private var personalDetails: String = ""
  @AppStorage("reducedMotion") private var reducedMotion: Bool = false
  @AppStorage("debugMode") private var debugMode: Bool = false
  @AppStorage("speakQuiz") private var speakQuiz: Bool = false

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
      Section(header: Text("Personal Details")) {
        Text("Write a description of who you are, what level of education you are studying, etc.")
          .font(.footnote)
          .foregroundColor(.secondary)

        TextEditor(text: $personalDetails)
          .frame(height: 100)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .disableAutocorrection(true)
          .autocapitalization(.none)
      }
      Section(header: Text("Debug Mode")) {
        Toggle("Enable Debug Mode", isOn: $debugMode)
          .toggleStyle(SwitchToggleStyle())
          .onChange(of: debugMode) { newValue in
            if newValue {
              print("Debug mode enabled")
            } else {
              print("Debug mode disabled")
            }
          }
      }
    Section(header: Text("Accessibility")) {
      Toggle("Reduce Motion", isOn: $reducedMotion)
        .toggleStyle(SwitchToggleStyle())
        .onChange(of: reducedMotion) { newValue in
          if newValue {
            print("Reduced motion enabled")
          } else {
            print("Reduced motion disabled")
          }
        }
      Toggle("Speak Quiz Questions", isOn: $speakQuiz)
        .toggleStyle(SwitchToggleStyle())
        .onChange(of: speakQuiz) { newValue in
          if newValue {
            print("Speak quiz questions enabled")
          } else {
            print("Speak quiz questions disabled")
          }
        }
    }}
    .navigationTitle("Preferences")
  }
}

#Preview {
  PreferencesView()
}
