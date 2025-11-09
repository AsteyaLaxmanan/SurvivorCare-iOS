//
//  JournalView.swift
//  SurvivorshipCareSwift
//
//  Created by Asteya Laxmanan on 11/9/25.
//

import SwiftUI

struct JournalView: View {
    @ObservedObject var store: JournalStore
    @State private var draft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Composer card
            VStack(alignment: .leading, spacing: 10) {
                Text("New Entry")
                    .font(.headline)

                TextEditor(text: $draft)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

                HStack {
                    Spacer()
                    Button {
                        store.add(draft)
                        draft = ""
                        isFocused = false
                    } label: {
                        Text("Save Entry").bold().frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.btAccent)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.06), lineWidth: 0.5))

            // Entries list
            if store.entries.isEmpty {
                Text("No entries yet. Your reflections will appear here.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            } else {
                List {
                    ForEach(store.entries) { e in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(e.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.footnote).foregroundStyle(.secondary)
                            Text(e.text)
                        }
                        .listRowBackground(Color(.secondarySystemBackground))
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: store.delete)
                }
                .listStyle(.plain)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal)
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { isFocused = store.entries.isEmpty }
    }
}
