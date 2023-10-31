#if os(iOS)

import SwiftUI
import Materials
import CommonExtensions

struct SearchView: View {

        init(placeholder: LocalizedStringKey = "Search", submitLabel: SubmitLabel = .search, animationState: Binding<Int>) {
                self.placeholder = placeholder
                self.submitLabel = submitLabel
                self._animationState = animationState
        }

        private let placeholder: LocalizedStringKey
        private let submitLabel: SubmitLabel
        @Binding private var animationState: Int

        @State private var inputText: String = String.empty
        @State private var cantonese: String = String.empty
        @State private var lexicon: CantoneseLexicon? = nil

        @State private var yingWaaEntries: [YingWaaFanWan] = []
        @State private var choHokEntries: [ChoHokYuetYamCitYiu] = []
        @State private var fanWanEntries: [FanWanCuetYiu] = []
        @State private var gwongWanEntries: [GwongWanCharacter] = []

        var body: some View {
                Section {
                        TextField(placeholder, text: $inputText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .submitLabel(submitLabel)
                                .onSubmit {
                                        let trimmedInput: String = inputText.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .controlCharacters)
                                        guard trimmedInput != cantonese else { return }
                                        defer {
                                                animationState += 1
                                        }
                                        guard !trimmedInput.isEmpty else {
                                                yingWaaEntries = []
                                                choHokEntries = []
                                                fanWanEntries = []
                                                gwongWanEntries = []
                                                lexicon = nil
                                                cantonese = String.empty
                                                return
                                        }
                                        yingWaaEntries = AppMaster.lookupYingWaaFanWan(for: trimmedInput)
                                        choHokEntries = AppMaster.lookupChoHokYuetYamCitYiu(for: trimmedInput)
                                        fanWanEntries = AppMaster.lookupFanWanCuetYiu(for: trimmedInput)
                                        gwongWanEntries = AppMaster.lookupGwongWan(for: trimmedInput)
                                        lexicon = AppMaster.lookupCantoneseLexicon(for: trimmedInput)
                                        cantonese = trimmedInput
                                }
                }
                if !cantonese.isEmpty {
                        Section {
                                CantoneseTextLabel(cantonese)
                                if let pronunciations = lexicon?.pronunciations {
                                        ForEach(0..<pronunciations.count, id: \.self) { index in
                                                PronunciationLabel(pronunciations[index])
                                        }
                                }
                        }
                        .textSelection(.enabled)
                }
                if !yingWaaEntries.isEmpty {
                        Section {
                                ForEach(0..<yingWaaEntries.count, id: \.self) { index in
                                        YingWaaFanWanLabel(entry: yingWaaEntries[index])
                                }
                        } header: {
                                Text(verbatim: yingWaaHeader).minimumScaleFactor(0.5).lineLimit(1).textCase(nil)
                        }
                        .textSelection(.enabled)
                }
                if !choHokEntries.isEmpty {
                        Section {
                                ForEach(0..<choHokEntries.count, id: \.self) { index in
                                        ChoHokYuetYamCitYiuLabel(entry: choHokEntries[index])
                                }
                        } header: {
                                Text(verbatim: choHokHeader).minimumScaleFactor(0.5).lineLimit(1).textCase(nil)
                        }
                        .textSelection(.enabled)
                }
                if !fanWanEntries.isEmpty {
                        Section {
                                ForEach(0..<fanWanEntries.count, id: \.self) { index in
                                        FanWanCuetYiuLabel(entry: fanWanEntries[index])
                                }
                        } header: {
                                Text(verbatim: fanWanHeader).minimumScaleFactor(0.5).lineLimit(1).textCase(nil)
                        }
                        .textSelection(.enabled)
                }
                if !gwongWanEntries.isEmpty {
                        Section {
                                ForEach(0..<gwongWanEntries.count, id: \.self) { index in
                                        GwongWanLabel(entry: gwongWanEntries[index])
                                }
                        } header: {
                                Text(verbatim: gwongWanHeader).minimumScaleFactor(0.5).lineLimit(1).textCase(nil)
                        }
                        .textSelection(.enabled)
                }
        }

        private let yingWaaMeta: String = "《英華分韻撮要》　衛三畏　1856　廣州"
        private let choHokMeta: String = "《初學粵音切要》　湛約翰　1855　香港"
        private let fanWamMeta: String = "《分韻撮要》"
        private let gwongWanMeta: String = "《大宋重修廣韻》"

        private var yingWaaHeader: String {
                guard let leading: String = yingWaaEntries.first?.word else { return yingWaaMeta }
                return leading + String.fullWidthSpace + yingWaaMeta
        }
        private var choHokHeader: String {
                guard let leading: String = choHokEntries.first?.word else { return choHokMeta }
                return leading + String.fullWidthSpace + choHokMeta
        }
        private var fanWanHeader: String {
                guard let leading: String = fanWanEntries.first?.word else { return fanWamMeta }
                return leading + String.fullWidthSpace + fanWamMeta
        }
        private var gwongWanHeader: String {
                guard let leading: String = gwongWanEntries.first?.word else { return gwongWanMeta }
                return leading + String.fullWidthSpace + gwongWanMeta
        }
}

#endif
