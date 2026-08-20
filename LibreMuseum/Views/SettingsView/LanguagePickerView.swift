import SwiftUI

struct LanguagePickerView: View {
    let languages: [LanguageUI]
    let selectedCode: String
    let onSelect: (String) -> Void

    var body: some View {
        Section {
            if languages.isEmpty {
                Text("No language available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(languages) { language in
                    Button {
                        onSelect(language.code)
                    } label: {
                        HStack {
                            Text(language.label)
                            Spacer()
                            if language.code == selectedCode {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .contentShape(.rect)
                    }

                    .buttonStyle(.plain)
                }
            }
        } header: {
            Text("Language")
        } footer: {
            Text("By default the app follows your phone's language when the museum offers it.")
        }
    }
}
