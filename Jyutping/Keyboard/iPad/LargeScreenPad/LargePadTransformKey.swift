import SwiftUI

struct LargePadTransformKey: View {

        init(destination: KeyboardForm, keyLocale: HorizontalEdge, widthUnitTimes: CGFloat) {
                self.destination = destination
                self.keyLocale = keyLocale
                self.keyText = {
                        switch destination {
                        case .alphabetic:
                                return "ABC"
                        case .numeric:
                                return ".?123"
                        case .symbolic:
                                return "#+="
                        default:
                                return "???"
                        }
                }()
                self.widthUnitTimes = widthUnitTimes
        }

        private let destination: KeyboardForm
        private let keyLocale: HorizontalEdge
        private let keyText: String
        private let widthUnitTimes: CGFloat

        @EnvironmentObject private var context: KeyboardViewController

        @Environment(\.colorScheme) private var colorScheme
        private var keyColor: Color {
                switch colorScheme {
                case .light:
                        return .lightEmphatic
                case .dark:
                        return .darkEmphatic
                @unknown default:
                        return .lightEmphatic
                }
        }
        private var activeKeyColor: Color {
                switch colorScheme {
                case .light:
                        return .light
                case .dark:
                        return .dark
                @unknown default:
                        return .light
                }
        }

        @GestureState private var isTouching: Bool = false

        var body: some View {
                ZStack {
                        Color.interactiveClear
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(isTouching ? activeKeyColor : keyColor)
                                .shadow(color: .black.opacity(0.4), radius: 0.5, y: 1)
                                .padding(4)
                        ZStack(alignment: keyLocale.isLeading ? .bottomLeading : .bottomTrailing) {
                                Color.clear
                                Text(verbatim: keyText)
                                        .padding(12)
                        }
                }
                .frame(width: context.widthUnit * widthUnitTimes, height: context.heightUnit)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                        .updating($isTouching) { _, tapped, _ in
                                if !tapped {
                                        AudioFeedback.modified()
                                        tapped = true
                                }
                        }
                        .onEnded { _ in
                                context.updateKeyboardForm(to: destination)
                         }
                )
        }
}
