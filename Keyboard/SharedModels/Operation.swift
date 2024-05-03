import CoreIME

enum Operation: Hashable {
        case input(String)
        case separate
        case process(String)
        case combine(Combo)
        case space
        case doubleSpace
        case backspace
        case clearBuffer
        case `return`
        case shift
        case doubleShift
        case tab
        case dismiss
        case select(Candidate)

        case copyAllText
        case cutAllText
        case clearLeadingText
        case convertAllText
        case clearClipboard
        case paste
        case moveCursorBackward
        case moveCursorForward
        case jumpToHead
        case jumpToTail
        case forwardDelete
}
