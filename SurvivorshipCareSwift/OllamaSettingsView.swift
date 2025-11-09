//
//  OllamaSettingsView.swift
//  SurvivorshipCareSwift
//
//  Created by Asteya Laxmanan on 11/8/25.
//


// OllamaSettingsView.swift
import SwiftUI

struct OllamaSettingsView: View {
    @Binding var ollamaBaseURL: String
    @Binding var ollamaModel: String

    var body: some View {
        Form {
            Section("Ollama Host") {
                TextField("http://172.20.10.3:11434", text: $ollamaBaseURL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            Section("Model") {
                TextField("llama3", text: $ollamaModel)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
        .navigationTitle("Ollama Settings")
    }
}
