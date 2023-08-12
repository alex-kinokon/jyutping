import SwiftUI

struct CommaKey: View {

        @EnvironmentObject private var context: KeyboardViewController

        @Environment(\.colorScheme) private var colorScheme
        private var keyColor: Color {
                switch colorScheme {
                case .light:
                        return .light
                case .dark:
                        return .dark
                @unknown default:
                        return .light
                }
        }
        private var keyPreviewColor: Color {
                switch colorScheme {
                case .light:
                        return .light
                case .dark:
                        return .darkOpacity
                @unknown default:
                        return .light
                }
        }

        @GestureState private var isTouching: Bool = false
        private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
        @State private var buffer: Int = 0
        @State private var isLongPressing: Bool = false
        @State private var selectedIndex: Int = 0

        private func responsiveSymbols(isABCMode: Bool, needsInputModeSwitchKey: Bool) -> [String] {
                guard isABCMode else { return ["，", "。", "？", "！"] }
                return needsInputModeSwitchKey ? [".", ",", "?", "!"] : [",", ".", "?", "!"]
        }

        var body: some View {
                ZStack {
                        if isLongPressing {
                                let symbols: [String] = responsiveSymbols(isABCMode: context.inputMethodMode.isABC, needsInputModeSwitchKey: context.needsInputModeSwitchKey)
                                let expansions: Int = symbols.count - 1
                                KeyPreviewRightExpansionPath(expansions: expansions)
                                        .fill(keyPreviewColor)
                                        .shadow(color: .black.opacity(0.4), radius: 0.5)
                                        .overlay {
                                                HStack(spacing: 0) {
                                                        ForEach(0..<symbols.count, id: \.self) { index in
                                                                ZStack {
                                                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                                                .fill(selectedIndex == index ? Color.selection : Color.clear)
                                                                        Text(verbatim: symbols[index])
                                                                                .font(.title)
                                                                                .foregroundStyle(selectedIndex == index ? Color.white : Color.primary)
                                                                }
                                                                .frame(maxWidth: .infinity)
                                                        }
                                                }
                                                .frame(width: context.widthUnit * CGFloat(expansions + 1), height: context.heightUnit - 10)
                                                .padding(.bottom, context.heightUnit * 2)
                                                .padding(.leading, context.widthUnit * CGFloat(expansions))
                                        }
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 3)
                        } else if isTouching {
                                KeyPreviewPath()
                                        .fill(keyPreviewColor)
                                        .shadow(color: .black.opacity(0.4), radius: 0.5)
                                        .overlay {
                                                CommaKeyText(isABCMode: context.inputMethodMode.isABC, needsInputModeSwitchKey: context.needsInputModeSwitchKey, isBuffering: context.inputStage.isBuffering, width: context.widthUnit, height: context.heightUnit)
                                                        .font(.largeTitle)
                                                        .padding(.bottom, context.heightUnit * 2)
                                        }
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 3)
                        } else {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(keyColor)
                                        .shadow(color: .black.opacity(0.4), radius: 0.5, y: 1)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 3)
                                CommaKeyText(isABCMode: context.inputMethodMode.isABC, needsInputModeSwitchKey: context.needsInputModeSwitchKey, isBuffering: context.inputStage.isBuffering, width: context.widthUnit, height: context.heightUnit)
                        }
                }
                .frame(width: context.widthUnit, height: context.heightUnit)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                        .updating($isTouching) { _, tapped, _ in
                                if !tapped {
                                        AudioFeedback.inputed()
                                        context.triggerHapticFeedback()
                                        tapped = true
                                }
                        }
                        .onChanged { value in
                                guard isLongPressing else { return }
                                let distance: CGFloat = value.translation.width
                                guard distance > 0 else { return }
                                let step: CGFloat = context.widthUnit
                                if distance < step {
                                        selectedIndex = 0
                                } else if distance < (step * 2) {
                                        selectedIndex = 1
                                } else if distance < (step * 3) {
                                        selectedIndex = 2
                                } else {
                                        selectedIndex = 3
                                }
                        }
                        .onEnded { _ in
                                buffer = 0
                                if isLongPressing {
                                        let symbols: [String] = responsiveSymbols(isABCMode: context.inputMethodMode.isABC, needsInputModeSwitchKey: context.needsInputModeSwitchKey)
                                        guard let selectedSymbol: String = symbols.fetch(selectedIndex) else { return }
                                        AudioFeedback.inputed()
                                        context.triggerSelectionHapticFeedback()
                                        context.operate(.input(selectedSymbol))
                                        selectedIndex = 0
                                        isLongPressing = false
                                } else {
                                        if context.inputMethodMode.isABC {
                                                if context.needsInputModeSwitchKey {
                                                        context.operate(.input("."))
                                                } else {
                                                        context.operate(.input(","))
                                                }
                                        } else {
                                                if context.inputStage.isBuffering {
                                                        context.operate(.process("'"))
                                                } else {
                                                        context.operate(.input("，"))
                                                }
                                        }
                                }
                         }
                )
                .onReceive(timer) { _ in
                        guard isTouching else { return }
                        if buffer > 4 {
                                let shouldPerformLongPress: Bool = !isLongPressing && !(context.inputStage.isBuffering)
                                if shouldPerformLongPress {
                                        isLongPressing = true
                                }
                        } else {
                                buffer += 1
                        }
                }
        }
}

private struct CommaKeyText: View {

        let isABCMode: Bool
        let needsInputModeSwitchKey: Bool
        let isBuffering: Bool
        let width: CGFloat
        let height: CGFloat

        var body: some View {
                if isABCMode {
                        if needsInputModeSwitchKey {
                                Text(verbatim: ".")
                        } else {
                                Text(verbatim: ",")
                        }
                } else {
                        if isBuffering {
                                Text(verbatim: "'")
                                VStack(spacing: 0) {
                                        Text(verbatim: " ").padding(.top, 12)
                                        Spacer()
                                        Text(verbatim: "分隔").font(.keyFooter).foregroundColor(.secondary).padding(.bottom, 12)
                                }
                                .frame(width: width, height:height)
                        } else {
                                Text(verbatim: "，")
                        }
                }
        }
}
