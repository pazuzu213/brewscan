import SwiftUI

struct SavedScanDetailView: View {
    @State private var scan: SavedScan
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var showAddNote = false
    @State private var newNoteText = ""
    @State private var editingNote: ScanNote? = nil
    @State private var editNoteText = ""
    @State private var showDeleteScanAlert = false
    @State private var showCatalogDetail = false

    private var db: PodDatabase { PodDatabase.shared }
    private var matchedPod: Pod? {
        guard let podId = scan.podId else { return nil }
        return db.pod(byId: podId)
    }

    init(scan: SavedScan) {
        _scan = State(initialValue: scan)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#1A0F0A").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        podHeader
                        VStack(alignment: .leading, spacing: 24) {
                            if let pod = matchedPod {
                                tastingNotesSection(pod: pod)
                                intensitySection(pod: pod)
                                originSection(pod: pod)
                                catalogButton
                            }
                            notesSection
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 48)
                    }
                }
            }
            .navigationTitle(scan.podName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "#1A0F0A"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#B0A090"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showDeleteScanAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red.opacity(0.75))
                    }
                }
            }
            .alert("Delete Scan?", isPresented: $showDeleteScanAlert) {
                Button("Delete", role: .destructive) {
                    appState.deleteScans(ids: [scan.id])
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove this scan and all its notes.")
            }
            .sheet(isPresented: $showAddNote) {
                addNoteSheet
            }
            .sheet(item: $editingNote) { note in
                editNoteSheet(note: note)
            }
            .sheet(isPresented: $showCatalogDetail) {
                if let pod = matchedPod {
                    PodDetailView(pod: pod)
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }

    // MARK: - Pod Header

    private var podHeader: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: scan.podColor).opacity(0.8),
                            Color(hex: "#1A0F0A")
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 170)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Color(hex: "#C8860A"))
                        .font(.system(size: 13))
                    Text("\(Int(scan.confidence * 100))% match")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#C8860A"))

                    Spacer()

                    Text(scan.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#B0A090"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.4))
                .cornerRadius(20)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(scan.podName)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)

                        HStack(spacing: 8) {
                            Text(scan.line)
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#C8860A").opacity(0.3))
                                .foregroundColor(Color(hex: "#C8860A"))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(hex: "#C8860A").opacity(0.4), lineWidth: 1)
                                )

                            Text("Intensity \(scan.intensity)")
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#2D1F15"))
                                .foregroundColor(Color(hex: "#C8860A"))
                                .cornerRadius(8)
                        }
                    }

                    Spacer()

                    Circle()
                        .fill(Color(hex: scan.podColor))
                        .frame(width: 52, height: 52)
                        .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 2))
                        .shadow(color: Color(hex: scan.podColor).opacity(0.6), radius: 12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Pod Detail Sections (from catalog)

    @ViewBuilder
    private func tastingNotesSection(pod: Pod) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Tasting Notes")
            FlowLayout(spacing: 8) {
                ForEach(pod.tastingNotes, id: \.self) { note in
                    Text(note)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#2D1F15"))
                        .foregroundColor(Color(hex: "#C8860A"))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#C8860A").opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func intensitySection(pod: Pod) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("Intensity")
                Spacer()
                Text("\(pod.intensity)/13")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#C8860A"))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#2D1F15"))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#C8A96E"),
                                    Color(hex: "#3D1A08")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * CGFloat(pod.intensity) / 13.0,
                            height: 12
                        )
                }
            }
            .frame(height: 12)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func originSection(pod: Pod) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Origin & Roast")
            VStack(spacing: 0) {
                infoRow(icon: "globe", label: "Origin", value: pod.origin)
                Divider().background(Color(hex: "#2D1F15"))
                infoRow(icon: "flame", label: "Roast", value: pod.roast)
                Divider().background(Color(hex: "#2D1F15"))
                infoRow(icon: "thermometer", label: "Brew Temp", value: pod.brewTemp)
            }
            .background(Color(hex: "#2D1F15"))
            .cornerRadius(16)
        }
        .padding(.horizontal, 20)
    }

    private var catalogButton: some View {
        Button(action: { showCatalogDetail = true }) {
            HStack {
                Image(systemName: "books.vertical")
                Text("View Full Profile in Catalog")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(hex: "#2D1F15"))
            .foregroundColor(Color(hex: "#C8860A"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "#C8860A").opacity(0.4), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("My Notes")

                if !scan.notes.isEmpty {
                    Text("\(scan.notes.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#1A0F0A"))
                        .frame(width: 18, height: 18)
                        .background(Color(hex: "#C8860A"))
                        .clipShape(Circle())
                }

                Spacer()

                Button {
                    newNoteText = ""
                    showAddNote = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Note")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#C8860A"))
                }
            }
            .padding(.horizontal, 20)

            if scan.notes.isEmpty {
                Text("No notes yet. Tap Add Note to capture your impressions.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#B0A090"))
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "#2D1F15"))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 1) {
                    ForEach(scan.notes.sorted { $0.date > $1.date }) { note in
                        noteRow(note: note)
                    }
                }
                .background(Color(hex: "#2D1F15"))
                .cornerRadius(16)
                .padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder
    private func noteRow(note: ScanNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#B0A090").opacity(0.7))

                Spacer()

                Button {
                    editNoteText = note.text
                    editingNote = note
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#C8860A"))
                        .padding(6)
                }

                Button {
                    deleteNote(note)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.7))
                        .padding(6)
                }
            }

            Text(note.text)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Add Note Sheet

    private var addNoteSheet: some View {
        NavigationView {
            ZStack {
                Color(hex: "#1A0F0A").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 12) {
                    Text("What did you notice about this pod?")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#B0A090"))

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $newNoteText)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(12)
                            .frame(minHeight: 130)
                            .background(Color(hex: "#2D1F15"))
                            .cornerRadius(16)
                            .scrollContentBackground(.hidden)

                        if newNoteText.isEmpty {
                            Text("Flavors, impressions, who you shared it with...")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#B0A090").opacity(0.5))
                                .padding(20)
                                .allowsHitTesting(false)
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "#1A0F0A"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showAddNote = false }
                        .foregroundColor(Color(hex: "#B0A090"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addNote()
                        showAddNote = false
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#C8860A"))
                    .disabled(newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }

    // MARK: - Edit Note Sheet

    private func editNoteSheet(note: ScanNote) -> some View {
        NavigationView {
            ZStack {
                Color(hex: "#1A0F0A").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Edit your note")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#B0A090"))

                    TextEditor(text: $editNoteText)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(12)
                        .frame(minHeight: 130)
                        .background(Color(hex: "#2D1F15"))
                        .cornerRadius(16)
                        .scrollContentBackground(.hidden)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "#1A0F0A"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { editingNote = nil }
                        .foregroundColor(Color(hex: "#B0A090"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateNote(note)
                        editingNote = nil
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#C8860A"))
                    .disabled(editNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }

    // MARK: - Actions

    private func addNote() {
        let note = ScanNote(
            id: UUID(),
            date: Date(),
            text: newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        scan.notes.append(note)
        appState.updateScan(scan)
    }

    private func updateNote(_ note: ScanNote) {
        let trimmed = editNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let idx = scan.notes.firstIndex(where: { $0.id == note.id }), !trimmed.isEmpty {
            scan.notes[idx].text = trimmed
            appState.updateScan(scan)
        }
    }

    private func deleteNote(_ note: ScanNote) {
        scan.notes.removeAll { $0.id == note.id }
        appState.updateScan(scan)
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(hex: "#B0A090"))
            .textCase(.uppercase)
            .tracking(1.5)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#C8860A"))
                .frame(width: 24)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#B0A090"))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
