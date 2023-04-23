import SwiftUI

extension JyutpingInputController {

        func resetWindow() {
                _ = window?.contentView?.subviews.map({ $0.removeFromSuperview() })
                _ = window?.contentViewController?.children.map({ $0.removeFromParent() })
                let frame: CGRect = windowFrame()
                if window == nil {
                        window = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
                        window?.collectionBehavior = .moveToActiveSpace
                        let levelValue: Int = Int(CGShieldingWindowLevel())
                        window?.level = NSWindow.Level(levelValue)
                        window?.backgroundColor = .clear
                }
                switch InputForm.current {
                case .options:
                        let optionsUI = NSHostingController(rootView: OptionsView().environmentObject(switchesObject))
                        window?.contentView?.addSubview(optionsUI.view)
                        optionsUI.view.translatesAutoresizingMaskIntoConstraints = false
                        if let topAnchor = window?.contentView?.topAnchor,
                           let bottomAnchor = window?.contentView?.bottomAnchor,
                           let leadingAnchor = window?.contentView?.leadingAnchor,
                           let trailingAnchor = window?.contentView?.trailingAnchor {
                                switch windowPattern {
                                case .regular:
                                        NSLayoutConstraint.activate([
                                                optionsUI.view.topAnchor.constraint(equalTo: topAnchor, constant: windowOffset),
                                                optionsUI.view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: windowOffset)
                                        ])
                                case .horizontalReversed:
                                        NSLayoutConstraint.activate([
                                                optionsUI.view.topAnchor.constraint(equalTo: topAnchor, constant: windowOffset),
                                                optionsUI.view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -windowOffset)
                                        ])
                                case .verticalReversed:
                                        NSLayoutConstraint.activate([
                                                optionsUI.view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -windowOffset),
                                                optionsUI.view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: windowOffset)
                                        ])
                                case .reversed:
                                        NSLayoutConstraint.activate([
                                                optionsUI.view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -windowOffset),
                                                optionsUI.view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -windowOffset)
                                        ])
                                }
                        }
                        window?.contentViewController?.addChild(optionsUI)
                        window?.setFrame(frame, display: true)
                        switchesObject.resetHighlightedIndex()
                default:
                        let candidatesUI = NSHostingController(rootView: CandidateBoard().environmentObject(displayObject))
                        window?.contentView?.addSubview(candidatesUI.view)
                        candidatesUI.view.translatesAutoresizingMaskIntoConstraints = false
                        if let topAnchor = window?.contentView?.topAnchor,
                           let bottomAnchor = window?.contentView?.bottomAnchor,
                           let leadingAnchor = window?.contentView?.leadingAnchor,
                           let trailingAnchor = window?.contentView?.trailingAnchor {
                                switch windowPattern {
                                case .regular:
                                        NSLayoutConstraint.activate([
                                                candidatesUI.view.topAnchor.constraint(equalTo: topAnchor, constant: windowOffset),
                                                candidatesUI.view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: windowOffset)
                                        ])
                                case .horizontalReversed:
                                        NSLayoutConstraint.activate([
                                                candidatesUI.view.topAnchor.constraint(equalTo: topAnchor, constant: windowOffset),
                                                candidatesUI.view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -windowOffset)
                                        ])
                                case .verticalReversed:
                                        NSLayoutConstraint.activate([
                                                candidatesUI.view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -windowOffset),
                                                candidatesUI.view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: windowOffset)
                                        ])
                                case .reversed:
                                        NSLayoutConstraint.activate([
                                                candidatesUI.view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -windowOffset),
                                                candidatesUI.view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -windowOffset)
                                        ])
                                }
                        }
                        window?.contentViewController?.addChild(candidatesUI)
                        window?.setFrame(.zero, display: true)
                }
                window?.orderFrontRegardless()
        }

        func windowFrame(size: CGSize = CGSize(width: 800, height: 500)) -> CGRect {
                let origin: CGPoint = currentOrigin ?? currentClient?.position ?? .zero
                let width: CGFloat = size.width
                let height: CGFloat = size.height
                let x: CGFloat = {
                        if windowPattern.isReversingHorizontal {
                                return origin.x - width - 8
                        } else {
                                return origin.x
                        }
                }()
                let y: CGFloat = {
                        if windowPattern.isReversingVertical {
                                return origin.y + 16
                        } else {
                                return origin.y - height
                        }
                }()
                return CGRect(x: x, y: y, width: width, height: height)
        }
}
