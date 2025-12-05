import SwiftUI

struct BookNotesView: View {
    let bookId: Int
    let bookTitle: String
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColors) var themeColors
    @EnvironmentObject var authManager: AuthManager
    @State private var notes: [Note] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var filterType: NoteFilterType = .all
    @State private var showingAddNote = false
    @State private var editingNote: Note? = nil

    enum NoteFilterType: String, CaseIterable {
        case all = "All"
        case myNotes = "My Notes"
        case publicNotes = "Public"

        var apiValue: String {
            switch self {
            case .all: return "all"
            case .myNotes: return "user"
            case .publicNotes: return "public"
            }
        }
    }

    var filteredNotes: [Note] {
        notes.sorted { ($0.dateCreated) > ($1.dateCreated) }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $filterType) {
                    ForEach(NoteFilterType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: filterType) { _ in
                    Task {
                        await loadNotes()
                    }
                }

                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading notes...")
                        Spacer()
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(themeColors.error)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(themeColors.textSecondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                await loadNotes()
                            }
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                    .padding()
                } else if notes.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "note.text")
                            .font(.system(size: 60))
                            .foregroundColor(themeColors.textSecondary.opacity(0.5))
                        Text("No notes yet")
                            .font(.title3)
                            .foregroundColor(themeColors.textSecondary)
                        Text("Be the first to add a note!")
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredNotes) { note in
                            NoteRowView(
                                note: note,
                                isOwnNote: note.userId == authManager.currentUser?.id,
                                onEdit: { note in
                                    editingNote = note
                                },
                                onDelete: { note in
                                    Task {
                                        await deleteNote(note)
                                    }
                                },
                                onToggleLike: { note in
                                    Task {
                                        await toggleLike(note)
                                    }
                                }
                            )
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await loadNotes()
                    }
                }
            }
            .navigationTitle("Notes - \(bookTitle)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddNote = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddNote) {
                AddNoteView(bookId: bookId, onSave: {
                    Task {
                        await loadNotes()
                    }
                })
            }
            .sheet(item: $editingNote) { note in
                EditNoteView(note: note, onSave: {
                    Task {
                        await loadNotes()
                    }
                })
            }
            .task {
                await loadNotes()
            }
        }
    }

    private func loadNotes() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIManager.shared.getBookNotes(
                bookId: bookId,
                type: filterType.apiValue
            )

            await MainActor.run {
                notes = response.notes ?? []
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load notes"
                isLoading = false
            }
        }
    }

    private func deleteNote(_ note: Note) async {
        do {
            try await APIManager.shared.deleteNote(noteId: note.id)
            await MainActor.run {
                notes.removeAll { $0.id == note.id }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to delete note"
            }
        }
    }

    private func toggleLike(_ note: Note) async {
        do {
            let response: NoteLikeResponse
            if note.isLiked == true {
                response = try await APIManager.shared.unlikeNote(noteId: note.id)
            } else {
                response = try await APIManager.shared.likeNote(noteId: note.id)
            }

            // Update the note in the list
            await MainActor.run {
                if let index = notes.firstIndex(where: { $0.id == note.id }) {
                    var updatedNote = notes[index]
                    // Create a new Note with updated values (since Note is a struct)
                    notes[index] = Note(
                        id: updatedNote.id,
                        bookId: updatedNote.bookId,
                        userId: updatedNote.userId,
                        noteText: updatedNote.noteText,
                        pageNumber: updatedNote.pageNumber,
                        isPublic: updatedNote.isPublic,
                        dateCreated: updatedNote.dateCreated,
                        dateModified: updatedNote.dateModified,
                        userName: updatedNote.userName,
                        userAvatar: updatedNote.userAvatar,
                        likeCount: response.likeCount,
                        isLiked: !(note.isLiked ?? false)
                    )
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to like/unlike note"
            }
        }
    }
}

struct NoteRowView: View {
    let note: Note
    let isOwnNote: Bool
    let onEdit: (Note) -> Void
    let onDelete: (Note) -> Void
    let onToggleLike: (Note) -> Void
    @Environment(\.themeColors) var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User info
            HStack(spacing: 8) {
                if let avatarUrl = note.userAvatar, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(themeColors.primary)
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(note.userName ?? "Unknown User")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 4) {
                        if let page = note.pageNumber {
                            Text("Page \(page)")
                                .font(.caption)
                                .foregroundColor(themeColors.textSecondary)
                            Text("•")
                                .font(.caption)
                                .foregroundColor(themeColors.textSecondary)
                        }

                        Text(note.dateCreated.toRelativeTime())
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)

                        if !note.isPublic {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(themeColors.textSecondary)
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(themeColors.textSecondary)
                        }
                    }
                }

                Spacer()

                if isOwnNote {
                    Menu {
                        Button {
                            onEdit(note)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            onDelete(note)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(themeColors.textSecondary)
                    }
                }
            }

            // Note content
            Text(note.noteText.decodingHTMLEntities)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            // Like button
            HStack(spacing: 16) {
                Button {
                    onToggleLike(note)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: note.isLiked == true ? "heart.fill" : "heart")
                            .foregroundColor(note.isLiked == true ? .red : themeColors.textSecondary)
                        if let count = note.likeCount, count > 0 {
                            Text("\(count)")
                                .font(.caption)
                                .foregroundColor(themeColors.textSecondary)
                        }
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(themeColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeColors.border, lineWidth: 1)
        )
    }
}

struct AddNoteView: View {
    let bookId: Int
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColors) var themeColors
    @State private var noteText = ""
    @State private var pageNumber = ""
    @State private var isPublic = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Note")) {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 150)
                }

                Section(header: Text("Details")) {
                    TextField("Page Number (optional)", text: $pageNumber)
                        .keyboardType(.numberPad)

                    Toggle("Public Note", isOn: $isPublic)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(themeColors.error)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await saveNote()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
    }

    private func saveNote() async {
        isSaving = true
        errorMessage = nil

        let page = Int(pageNumber.trimmingCharacters(in: .whitespacesAndNewlines))

        do {
            _ = try await APIManager.shared.createNote(
                bookId: bookId,
                noteText: noteText,
                pageNumber: page,
                isPublic: isPublic
            )

            await MainActor.run {
                isSaving = false
                onSave()
                dismiss()
            }
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = "Failed to save note"
            }
        }
    }
}

struct EditNoteView: View {
    let note: Note
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColors) var themeColors
    @State private var noteText: String
    @State private var pageNumber: String
    @State private var isPublic: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(note: Note, onSave: @escaping () -> Void) {
        self.note = note
        self.onSave = onSave
        _noteText = State(initialValue: note.noteText)
        _pageNumber = State(initialValue: note.pageNumber.map { "\($0)" } ?? "")
        _isPublic = State(initialValue: note.isPublic)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Note")) {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 150)
                }

                Section(header: Text("Details")) {
                    TextField("Page Number (optional)", text: $pageNumber)
                        .keyboardType(.numberPad)

                    Toggle("Public Note", isOn: $isPublic)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(themeColors.error)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await saveNote()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
    }

    private func saveNote() async {
        isSaving = true
        errorMessage = nil

        let page = Int(pageNumber.trimmingCharacters(in: .whitespacesAndNewlines))

        do {
            _ = try await APIManager.shared.updateNote(
                noteId: note.id,
                noteText: noteText,
                pageNumber: page,
                isPublic: isPublic
            )

            await MainActor.run {
                isSaving = false
                onSave()
                dismiss()
            }
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = "Failed to update note"
            }
        }
    }
}
