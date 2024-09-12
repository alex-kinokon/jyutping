import SwiftUI

struct TenKeySidebar: View {

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

        @Namespace private var topID

        var body: some View {
                ZStack {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(keyColor)
                                .shadow(color: .shadowGray, radius: 0.5, y: 0.5)
                        ScrollViewReader { proxy in
                                ScrollView(.vertical) {
                                        LazyVStack(spacing: 0) {
                                                EmptyView().id(topID)
                                                ForEach(context.sidebarTexts.indices, id: \.self) { index in
                                                        let text: String = context.sidebarTexts[index]
                                                        ScrollViewButton {
                                                                AudioFeedback.inputed()
                                                                context.triggerHapticFeedback()
                                                                if context.inputStage.isBuffering {
                                                                        // FIXME: Handle tapping
                                                                        // context.operate(.toggle(text))
                                                                } else {
                                                                        context.operate(.input(text))
                                                                }
                                                                withAnimation {
                                                                        proxy.scrollTo(topID)
                                                                }
                                                        } label: {
                                                                ZStack {
                                                                        Color.interactiveClear
                                                                        Text(verbatim: text)
                                                                }
                                                                .frame(height: context.heightUnit * 3.0 / 4.0 - 1.0)
                                                                .frame(maxWidth: .infinity)
                                                        }
                                                        Divider()
                                                }
                                        }
                                }
                        }
                }
                .padding(3)
                .frame(width: context.widthUnit * 2, height: context.heightUnit * 3)
        }
}
