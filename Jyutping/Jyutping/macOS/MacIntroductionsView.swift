#if os(macOS)

import SwiftUI

struct MacIntroductionsView: View {

        private let tonesInputDescription: String = NSLocalizedString("tones.input.description", comment: "")
        private let strokes: String = """
        w = 橫(waang)
        s = 豎(syu)
        a = 撇
        d = 點(dim)
        z = 折(zit)
        """

        var body: some View {
                ScrollView {
                        LazyVStack(spacing: 16) {
                                VStack(spacing: 16) {
                                        HStack {
                                                Text("Tones Input").font(.significant)
                                                Spacer()
                                        }
                                        HStack {
                                                Text(verbatim: tonesInputDescription).font(.fixedWidth).lineSpacing(5)
                                                Spacer()
                                        }
                                }
                                .block()

                                BlockView(heading: "Lookup Jyutping with Cangjie", content: "Cangjie Reverse Lookup Description")
                                BlockView(heading: "Lookup Jyutping with Pinyin", content: "Pinyin Reverse Lookup Description")

                                VStack(spacing: 16) {
                                        HStack {
                                                Text("Lookup Jyutping with Stroke").font(.significant)
                                                Spacer()
                                        }
                                        HStack {
                                                Text("Stroke Reverse Lookup Description").lineSpacing(6)
                                                Spacer()
                                        }
                                        HStack {
                                                Text(verbatim: strokes).font(.fixedWidth).lineSpacing(5)
                                                Spacer()
                                        }
                                }
                                .block()

                                BlockView(heading: "Lookup Jyutping with Loengfan", content: "Loengfan Reverse Lookup Description")
                        }
                        .textSelection(.enabled)
                        .padding()
                }
                .navigationTitle("Introductions")
        }
}


private struct BlockView: View {

        let heading: LocalizedStringKey
        let content: LocalizedStringKey

        var body: some View {
                VStack(spacing: 16) {
                        HStack {
                                Text(heading).font(.significant)
                                Spacer()
                        }
                        HStack {
                                Text(content).font(.master).lineSpacing(6)
                                Spacer()
                        }
                }
                .block()
        }
}

#endif
