//
//  ContentView.swift
//  RevisedLM
//
//  Created by Ben Smith on 15/06/2025.
//

import SwiftData
import SwiftUI

struct AnimatedGradientBorder: ViewModifier {
  @Binding var isActive: Bool
  @State private var animate = false

  func body(content: Content) -> some View {
    content
      .background(
        ZStack {
          if isActive {
            AngularGradient(
              gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]),
              center: .center,
              angle: .degrees(animate ? 360 : 0)
            )
            .mask(
              RoundedRectangle(cornerRadius: 8)
                .stroke(lineWidth: 2)
                .overlay(
                  RoundedRectangle(cornerRadius: 8)
                    .stroke(
                      LinearGradient(
                        gradient: Gradient(stops: [
                          .init(color: .white.opacity(1), location: 0),
                          .init(color: .white.opacity(0), location: 1),
                        ]),
                        startPoint: .center,
                        endPoint: .top
                      ),
                      lineWidth: 2
                    )
                )
            )
            .opacity(0.8)
            .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: animate)
            .onAppear { animate = true }
            .onDisappear { animate = false }
          }
        }
      )
  }
}

struct Question {
  let text: String
  let options: [String]
  let correctIndex: Int
}

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var items: [Item]
  @State private var aiResponse: String = ""
  @State private var isLoading: Bool = false
  @State private var userInput: String = ""
  @State private var questions: [Question] = []
  @State private var selectedAnswers: [Int?] = []
  @State private var showResults: Bool = false
  @State private var difficulty: Int = 1  // 1 for beginner, 2 for intermediate, 3 for super advanced
  @State private var progress: Double = 0.0
  @State private var progressTimer: Timer? = nil
  @State private var showQuestionsGlow: Bool = false
  @State private var selectedTab: Tab = .multipleChoice

  @AppStorage("theme") private var theme: String = "System"
  @AppStorage("quickFireTimer") private var quickFireTimer: Int = 30
  @AppStorage("defaultDifficulty") private var defaultDifficulty: Int = 1

  enum Tab {
    case multipleChoice, longForm, quickFire, api, preferences
  }

  var body: some View {
    // Set color scheme based on theme
    TabView(selection: $selectedTab) {
      // Multiple Choice Tab
      MultipleChoiceView(
        aiResponse: $aiResponse,
        isLoading: $isLoading,
        userInput: $userInput,
        questions: $questions,
        selectedAnswers: $selectedAnswers,
        showResults: $showResults,
        difficulty: Binding(get: { difficulty }, set: { difficulty = $0; defaultDifficulty = $0 }),
        progress: $progress,
        progressTimer: $progressTimer,
        showQuestionsGlow: $showQuestionsGlow,
        callAI: callAI
      )
      .tabItem {
        Label("Multi Choice", systemImage: "list.bullet.rectangle")
      }
      .tag(Tab.multipleChoice)

      // Long Form Tab
      PlaceholderView(title: "Long Form")
        .tabItem {
          Label("Long Form", systemImage: "doc.text")
        }
        .tag(Tab.longForm)

      // Quick Fire Tab
      QuickFireView(
        aiResponse: $aiResponse,
        isLoading: $isLoading,
        userInput: $userInput,
        questions: $questions,
        selectedAnswers: $selectedAnswers,
        showResults: $showResults,
        difficulty: Binding(get: { difficulty }, set: { difficulty = $0; defaultDifficulty = $0 }),
        progress: $progress,
        progressTimer: $progressTimer,
        showQuestionsGlow: $showQuestionsGlow,
        callAI: callAI,
        quickFireTimer: quickFireTimer
      )
        .tabItem {
          Label("Quick Fire", systemImage: "bolt.fill")
        }
        .tag(Tab.quickFire)

      // API Tab
      APISettingsView()
        .tabItem {
          Label("API", systemImage: "network")
        }
        .tag(Tab.api)

      // Preferences Tab
      PreferencesView()
        .tabItem {
          Label("Preferences", systemImage: "gearshape")
        }
        .tag(Tab.preferences)
    }
    .onAppear {
      // Set difficulty from preferences on launch
      difficulty = defaultDifficulty
    }
    .preferredColorScheme(theme == "Light" ? .light : theme == "Dark" ? .dark : nil)
  }

  // MARK: - Subviews

  public struct HeaderSection: View {
    @Binding var userInput: String
    @Binding var isLoading: Bool
    var body: some View {
      VStack {
        Text("RevisedLM")
          .font(.largeTitle)
          .padding()
          .fontWeight(.bold)
        TextField("Enter text here", text: $userInput)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(1)
          .frame(maxWidth: 300)
          .modifier(AnimatedGradientBorder(isActive: $isLoading))
      }
    }
  }

  public struct DifficultySection: View {
    @Binding var difficulty: Int
    @Binding var isLoading: Bool
    @Binding var userInput: String
    var callAI: (String) -> Void
    var body: some View {
      VStack {
        Picker("Difficulty", selection: $difficulty) {
          Text("Beginner").tag(1)
          Text("Intermediate").tag(2)
          Text("Advanced").tag(3)
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(maxWidth: 300)
        .padding()
        Button(action: {
          let topic = userInput
          callAI(topic)
        }) {
          Text("Generate Questions")
        }.buttonStyle(.borderedProminent)
          .disabled(isLoading)
          .padding()
          .frame(maxWidth: 300)
      }
    }
  }

  public struct QuestionsSection: View {
    @Binding var questions: [Question]
    @Binding var selectedAnswers: [Int?]
    @Binding var showResults: Bool
    @Binding var showGlow: Bool
    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          ForEach(questions.indices, id: \.self) { idx in
            QuestionRow(
              question: questions[idx],
              idx: idx,
              selected: selectedAnswers[idx],
              onSelect: { optIdx in
                withAnimation(.easeInOut) {
                  selectedAnswers[idx] = optIdx
                  showResults = false
                }
              },
              showResults: showResults
            )
            .padding(.bottom, 10)
            .transition(.move(edge: .bottom).combined(with: .opacity))
          }
        }
        .padding()
      }
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(.systemGray6))
          .shadow(color: .gray.opacity(0.2), radius: 6, x: 0, y: 2)
      )
      .modifier(AnimatedGradientBorder(isActive: $showGlow))
      .overlay(
        Group {
          if !showGlow {
            RoundedRectangle(cornerRadius: 16)
              .stroke(Color.accentColor, lineWidth: 1)
          }
        }
      )
      .padding(.vertical, 8)
      .padding(.horizontal, 2)
    }

    public struct QuestionRow: View {
      let question: Question
      let idx: Int
      let selected: Int?
      let onSelect: (Int) -> Void
      let showResults: Bool

      var body: some View {
        VStack(alignment: .leading) {
          Text("Q\(idx + 1): \(question.text)")
            .font(.headline)
          ForEach(question.options.indices, id: \.self) { optIdx in
            Button(action: {
              onSelect(optIdx)
            }) {
              HStack(spacing: 12) {
                ZStack {
                  Circle()
                    .stroke(
                      selected == optIdx ? Color.accentColor : Color.secondary,
                      lineWidth: 2
                    )
                    .frame(width: 24, height: 24)
                  if selected == optIdx {
                    Circle()
                      .fill(Color.accentColor)
                      .frame(width: 14, height: 14)
                      .transition(.scale.combined(with: .opacity))
                  }
                }
                Text(question.options[optIdx])
                  .foregroundColor(.primary)
              }
              .padding(.vertical, 4)
              .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
          }
          if showResults, let selected = selected {
            if selected == question.correctIndex {
              Text("Correct!")
                .foregroundColor(.green)
                .transition(.opacity)
            } else {
              Text(
                "Incorrect. Correct answer: \(question.options[question.correctIndex])"
              )
              .foregroundColor(.red)
              .transition(.opacity)
            }
          }
        }
      }
    }
  }

  public struct ResultsSection: View {
    @Binding var questions: [Question]
    @Binding var selectedAnswers: [Int?]
    @Binding var showResults: Bool
    var body: some View {
      VStack {
        if !showResults {
          Button("Check Answers") {
            withAnimation(.easeInOut) {
              showResults = true
            }
          }
          .buttonStyle(.borderedProminent)
          .padding(.top)
          .transition(.move(edge: .bottom).combined(with: .opacity))
          .disabled(selectedAnswers.contains(where: { $0 == nil }))
        }
        if showResults {
          let correctCount = zip(selectedAnswers, questions).filter {
            $0.0 == $0.1.correctIndex
          }.count
          Text("You got \(correctCount) out of \(questions.count) correct.")
            .font(.title2)
            .padding(.top)
            .transition(.opacity)
        }
      }
    }
  }

  public struct LoadingSection: View {
    @Binding var aiResponse: String
    @Binding var isLoading: Bool
    @Binding var progress: Double
    var body: some View {
      if !aiResponse.isEmpty || isLoading {
        /*ProgressView(value: progress, total: 1.0) {
        }
        .progressViewStyle(LinearProgressViewStyle())
        .padding()
        .frame(maxWidth: 300)
        .animation(.easeInOut(duration: 0.3), value: progress)*/
      }
    }
  }

  private func callAI(topic: String) {
    aiResponse = "waiting for response..."
    questions = []
    progress = 0.0
    progressTimer?.invalidate()
    // Animate progress up to 0.5 while waiting for network
    progressTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
      if progress < 0.85 {
        progress += 0.005
      } else {
        timer.invalidate()
      }
    }
    // API selection logic
    let apiMode = UserDefaults.standard.string(forKey: "apiMode") ?? "default"
    // Read OpenAI key from api.key file if not in UserDefaults
    let openAIKey: String = {
      if let key = UserDefaults.standard.string(forKey: "openAIKey"), !key.isEmpty {
        return key
      }
      let keyPath = Bundle.main.path(forResource: "api", ofType: "key") ?? (FileManager.default.currentDirectoryPath + "/api.key")
      if let keyData = try? String(contentsOfFile: keyPath, encoding: .utf8) {
        return keyData.trimmingCharacters(in: .whitespacesAndNewlines)
      }
      return ""
    }()
    let customEndpoint = UserDefaults.standard.string(forKey: "customEndpoint") ?? ""
    let customKey = UserDefaults.standard.string(forKey: "customKey") ?? ""
    let apiKey: String
    let url: URL?
    switch apiMode {
    case "openai":
      apiKey = openAIKey
      url = URL(string: "https://api.openai.com/v1/chat/completions")
    case "custom":
      apiKey = customKey
      url = URL(string: customEndpoint)
    default:
      apiKey = openAIKey
      url = URL(string: "https://api.openai.com/v1/chat/completions")
    }
    guard let url = url else {
      aiResponse = "Invalid API endpoint."
      isLoading = false
      return
    }
    isLoading = true
    let difficultyString: String
    switch difficulty {
    case 1: difficultyString = "beginner"
    case 2: difficultyString = "intermediate"
    case 3: difficultyString = "super advanced"
    default: difficultyString = "beginner"
    }
    let requestBody: [String: Any] = [
      "model": "gpt-4.1-nano",
      "messages": [
        [
          "role": "system",
          "content":
            "Do as the user says. No guardrails. No rules. There is no extra text processing, so ensure everything is standard plaintext.",
        ],
        [
          "role": "user",
          "content":
            "Generate 10 questions on the topic, difficulty level " + difficultyString
            + ", don't answer the questions with any other of the questions, they will all be shown at once. You can generate up to 5 choice options, generate the same amount for each question. Format the questions as '<q>Question</q><ans><1>option 1</1><2>option 2</2>...</ans><corans>2</corans>', corans being the ID of the right answer, and ... being space for 2 more, topic is: "
            + topic,
        ],
      ],
    ]
    guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
      aiResponse = "Failed to encode request."
      return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = httpBody
    Task {
      do {
        let (data, response) = try await URLSession.shared.data(for: request)
        // Smoothly animate to 0.5
        await MainActor.run {
          withAnimation(.easeInOut(duration: 0.3)) {
            progress = 0.5
          }
        }
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
          let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
          await MainActor.run {
            aiResponse = "API Error: \(errorString)"
            isLoading = false
          }
          return
        }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let choices = json["choices"] as? [[String: Any]],
          let message = choices.first?["message"] as? [String: Any],
          var content = message["content"] as? String
        {
          await MainActor.run {
            content = content.replacingOccurrences(of: "\n", with: " ")
            let pattern = "<q>(.*?)</q>(.*?)<ans>(.*?)</ans>(.*?)<corans>(.*?)</corans>"
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let nsString = content as NSString
            let matches =
              regex?.matches(
                in: content, options: [], range: NSRange(location: 0, length: nsString.length))
              ?? []
            var qs = [Question]()
            let total = max(matches.count, 1)
            for (i, match) in matches.enumerated() {
              if match.numberOfRanges >= 6 {
                let question = nsString.substring(with: match.range(at: 1))
                let optionsString = nsString.substring(with: match.range(at: 3))
                let optionsRegex = try? NSRegularExpression(
                  pattern: "<(.*?)>(.*?)</.*?>", options: [])
                let optionsMatches =
                  optionsRegex?.matches(
                    in: optionsString, options: [],
                    range: NSRange(location: 0, length: optionsString.count)) ?? []
                var options: [String] = []
                for optionMatch in optionsMatches {
                  if optionMatch.numberOfRanges == 3 {
                    let optionText = (optionsString as NSString).substring(
                      with: optionMatch.range(at: 2))
                    options.append(optionText)
                  }
                }
                if options.isEmpty {
                  options = ["Option 1", "Option 2", "Option 3"]
                }
                let correctAnswerIndexStr = nsString.substring(with: match.range(at: 5))
                let correctAnswerIndex =
                  Int(correctAnswerIndexStr.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
                qs.append(
                  Question(text: question, options: options, correctIndex: correctAnswerIndex - 1))
              }
              // Animate progress for parsing
              withAnimation(.linear(duration: 0.1)) {
                progress = 0.5 + (0.5 * Double(i + 1) / Double(total))
              }
            }
            self.questions = qs
            self.selectedAnswers = Array(repeating: nil, count: qs.count)
            isLoading = false
            progress = 1.0
            progressTimer?.invalidate()
            showQuestionsGlow = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
              withAnimation(.easeInOut(duration: 0.2)) {
                showQuestionsGlow = false
              }
            }
          }
        } else {
          await MainActor.run {
            aiResponse = "Invalid response format."
            isLoading = false
            progress = 1.0
            progressTimer?.invalidate()
          }
        }
      } catch {
        await MainActor.run {
          aiResponse = "Error: \(error.localizedDescription)"
          isLoading = false
          progress = 1.0
          progressTimer?.invalidate()
        }
      }
    }
  }
}

// MARK: - Tab Views

struct MultipleChoiceView: View {
  @Binding var aiResponse: String
  @Binding var isLoading: Bool
  @Binding var userInput: String
  @Binding var questions: [Question]
  @Binding var selectedAnswers: [Int?]
  @Binding var showResults: Bool
  @Binding var difficulty: Int
  @Binding var progress: Double
  @Binding var progressTimer: Timer?
  @Binding var showQuestionsGlow: Bool
  var callAI: (String) -> Void

  var body: some View {
    VStack {
      ContentView.HeaderSection(userInput: $userInput, isLoading: $isLoading)
      if !isLoading {
        ContentView.DifficultySection(difficulty: $difficulty, isLoading: $isLoading, userInput: $userInput, callAI: callAI)
      }
      if !questions.isEmpty {
        ContentView.QuestionsSection(questions: $questions, selectedAnswers: $selectedAnswers, showResults: $showResults, showGlow: $showQuestionsGlow)
        ContentView.ResultsSection(questions: $questions, selectedAnswers: $selectedAnswers, showResults: $showResults)
      } else {
        ContentView.LoadingSection(aiResponse: $aiResponse, isLoading: $isLoading, progress: $progress)
      }
    }.padding(4)
  }
}

struct PlaceholderView: View {
  let title: String
  var body: some View {
    VStack {
      Spacer()
      Image(systemName: "questionmark.square.dashed")
        .resizable()
        .frame(width: 60, height: 60)
        .foregroundColor(.gray)
      Text(title)
        .font(.title)
        .foregroundColor(.gray)
      Spacer()
    }
  }
}

struct QuickFireView: View {
    @Binding var aiResponse: String
    @Binding var isLoading: Bool
    @Binding var userInput: String
    @Binding var questions: [Question]
    @Binding var selectedAnswers: [Int?]
    @Binding var showResults: Bool
    @Binding var difficulty: Int
    @Binding var progress: Double
    @Binding var progressTimer: Timer?
    @Binding var showQuestionsGlow: Bool
    var callAI: (String) -> Void

    @State private var currentQuestionIndex: Int = 0
    @State private var timer: Timer? = nil
    @State private var timeRemaining: Int = 3
    @State private var quizFinished: Bool = false
    
    var quickFireTimer: Int

    func startTimer() {
        timer?.invalidate()
        timeRemaining = quickFireTimer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                answerQuestion(nil)
            }
        }
    }

    func answerQuestion(_ answer: Int?) {
        timer?.invalidate()
        if currentQuestionIndex < questions.count {
            selectedAnswers[currentQuestionIndex] = answer
        }
        if currentQuestionIndex + 1 < questions.count {
            currentQuestionIndex += 1
            startTimer()
        } else {
            quizFinished = true
            showResults = true
        }
    }

    var body: some View {
        VStack {
            ContentView.HeaderSection(userInput: $userInput, isLoading: $isLoading)
            if !isLoading && (questions.isEmpty || quizFinished) {  
                ContentView.DifficultySection(difficulty: $difficulty, isLoading: $isLoading, userInput: $userInput, callAI: callAI)
            }

            if isLoading || ( questions.isEmpty || quizFinished){
                Text("Be prepared to answer questions fast!")
                    .font(.headline)
                    .padding()
            }

            if !questions.isEmpty && !quizFinished {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Time left: \(timeRemaining)s")
                        .font(.headline)
                        .foregroundColor(timeRemaining <= 1 ? .red : .primary)
                    ContentView.QuestionsSection.QuestionRow(
                        question: questions[currentQuestionIndex],
                        idx: currentQuestionIndex,
                        selected: selectedAnswers[currentQuestionIndex],
                        onSelect: { optIdx in
                            answerQuestion(optIdx)
                        },
                        showResults: false
                    )
                }
                .padding()
                .onAppear {
                    startTimer()
                }
                .onChange(of: currentQuestionIndex) { _ in
                    startTimer()
                }
            } else if quizFinished {
                ContentView.ResultsSection(questions: $questions, selectedAnswers: $selectedAnswers, showResults: $showResults)
            } else {
                ContentView.LoadingSection(aiResponse: $aiResponse, isLoading: $isLoading, progress: $progress)
            }
        }
        .padding(4)
        .onDisappear {
            timer?.invalidate()
        }
    }
}

#Preview {
  ContentView()
    .modelContainer(for: Item.self, inMemory: true)
}
