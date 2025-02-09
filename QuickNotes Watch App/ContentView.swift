//
//  ContentView.swift
//  QuickNotes Watch App
//
//  Created by Riley Knybel on 2/6/25.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var viewModel = NotesViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(viewModel.notes) { note in
                        NavigationLink(destination: NoteDetailView(note: note)) {
                            Text(truncateText(note.text))
                        }
                    }
                    .padding()
                    .onDelete(perform: viewModel.deleteNote)
                }
                .listStyle(.plain) // Keeps the list clean
               
                Spacer() // Pushes the button down

                Button("Add Note") {
                    showDictation()
                }
                .buttonStyle(.borderedProminent) // Makes it compact
                .frame(height: 20) // Reduces button size
                .padding(.bottom, 10)
                .tint(.green)
            }
            .navigationTitle("Quick Notes") // Moves title to top left
        }
    }
    
    func truncateText(_ text: String, limit: Int = 20) -> String {
        if text.count > limit {
            let index = text.index(text.startIndex, offsetBy: limit)
            return String(text[..<index]) + "..."
        } else {
            return text
        }
    }
    
    func showDictation() {
        guard let controller = WKExtension.shared().visibleInterfaceController as? WKInterfaceController else {
            print("Could not get WKInterfaceController")
            return
        }
        
        controller.presentTextInputController(withSuggestions: nil, allowedInputMode: .plain) { result in
            if let results = result as? [String], let spokenText = results.first {
                DispatchQueue.main.async {
                    viewModel.addNote(text: spokenText)
                }
            }
        }
    }
}

struct NoteDetailView: View {
    let note: QuickNote

    var body: some View {
        ScrollView {
            Text(note.text)
                .padding()
        }
        .navigationTitle("Note")
    }
}

// Note Model
struct QuickNote: Identifiable, Codable {
    let id: UUID
    var text: String
    var date: Date
}

// ViewModel for Managing Notes
class NotesViewModel: ObservableObject {
    @Published var notes: [QuickNote] = []
    
    private let storageKey = "quickNotes"

    init() {
        loadNotes()
    }

    func addNote(text: String) {
        let newNote = QuickNote(id: UUID(), text: text, date: Date())
        notes.append(newNote)
        saveNotes()
    }

    func deleteNote(at indexSet: IndexSet) {
        notes.remove(atOffsets: indexSet)
        saveNotes()
    }

    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadNotes() {
        if let savedData = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([QuickNote].self, from: savedData) {
            notes = decoded
        }
    }
}

#Preview {
    ContentView()
}
