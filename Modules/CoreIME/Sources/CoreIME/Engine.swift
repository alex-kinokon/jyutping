import Foundation
import SQLite3

extension Lychee {

        fileprivate typealias RowCandidate = (candidate: CoreCandidate, row: Int)

        public static func suggest(for text: String, schemes: [[String]]) -> [CoreCandidate] {
                let startsWithY: Bool = text.hasPrefix("y")
                switch text.count {
                case 0:
                        return []
                case 1:
                        return shortcut(for: text)
                case 2 where !startsWithY:
                        return fetchTwoChars(text)
                case 3 where !(startsWithY || text.hasSuffix("um") || text.hasSuffix("om")):
                        return fetchThreeChars(text)
                default:
                        let filtered: String = text.replacingOccurrences(of: "'", with: "")
                        return fetch(for: filtered, origin: text, schemes: schemes)
                }
        }

        private static func fetchTwoChars(_ text: String) -> [CoreCandidate] {
                guard let firstChar = text.first, let lastChar = text.last else { return [] }
                guard !(firstChar.isSeparator || firstChar.isTone) else { return [] }
                guard !lastChar.isSeparator else { return match(for: String(firstChar)) }
                let matched: [CoreCandidate] = match(for: text)
                guard !lastChar.isTone else { return matched }
                let shortcutTwo: [CoreCandidate] = shortcut(for: text)
                let shortcutFirst: [CoreCandidate] = shortcut(for: String(firstChar))
                return matched + shortcutTwo + shortcutFirst
        }
        private static func fetchThreeChars(_ text: String) -> [CoreCandidate] {
                guard let firstChar = text.first, let lastChar = text.last else { return [] }
                guard !(firstChar.isSeparator || firstChar.isTone) else { return [] }
                let medium = text[text.index(text.startIndex, offsetBy: 1)]
                let leadingTwo: String = String([firstChar, medium])
                let headTail: String = String([firstChar, lastChar])
                if medium.isSeparator {
                        if lastChar.isSeparator || lastChar.isTone {
                                return match(for: String(firstChar))
                        } else {
                                return prefix(match: headTail)
                        }
                } else if medium.isTone {
                        guard !(lastChar.isSeparator || lastChar.isTone) else {
                                return match(for: leadingTwo)
                        }
                        let fetches: [CoreCandidate] = prefix(match: headTail)
                        let filtered: [CoreCandidate] = fetches.filter {
                                guard let first: String = $0.romanization.components(separatedBy: String.space).first else { return false }
                                return first == leadingTwo
                        }
                        return filtered
                }
                if lastChar.isSeparator {
                        return match(for: leadingTwo)
                } else if lastChar.isTone {
                        return match(for: text)
                }
                let exactly: [CoreCandidate] = match(for: text)
                let prefixes: [CoreCandidate] = prefix(match: text)
                let shortcutThree: [CoreCandidate] = shortcut(for: text)
                let shortcutTwo: [CoreCandidate] = shortcut(for: leadingTwo)
                let matchTwo: [CoreCandidate] = match(for: leadingTwo)
                let shortcutFirst: [CoreCandidate] = shortcut(for: String(firstChar))

                var combine: [CoreCandidate] = []
                if let shortcutLast1: CoreCandidate = shortcut(for: String(lastChar), count: 1).first {
                        if let firstMatchTwo: CoreCandidate = matchTwo.first {
                                let new: CoreCandidate = firstMatchTwo + shortcutLast1
                                combine.append(new)
                        }
                        if let firstShortcutTwo: CoreCandidate = matchTwo.first {
                                let new: CoreCandidate = firstShortcutTwo + shortcutLast1
                                combine.append(new)
                        }
                }
                let head: [CoreCandidate] = exactly + prefixes + shortcutThree
                let tail: [CoreCandidate] = combine + shortcutTwo + matchTwo + shortcutFirst
                return head + tail
        }

        private static func fetch(for text: String, origin: String, schemes: [[String]]) -> [CoreCandidate] {
                guard let bestScheme: [String] = schemes.first, !bestScheme.isEmpty else {
                        return processUnsplittable(text)
                }
                let modifiedText = text.replacingOccurrences(of: "(?<!c|s|j|z)yu(?!k|m|ng)", with: "jyu", options: .regularExpression)
                if bestScheme.joined().count == modifiedText.count {
                        return process(text: modifiedText, origin: origin, sequences: schemes)
                } else {
                        return processPartial(text: text, origin: origin, sequences: schemes)
                }
        }

        private static func processUnsplittable(_ text: String) -> [CoreCandidate] {
                var combine: [CoreCandidate] = match(for: text) + prefix(match: text) + shortcut(for: text)
                for number in 1..<text.count {
                        let leading: String = String(text.dropLast(number))
                        combine += shortcut(for: leading)
                }
                return combine
        }
        private static func process(text: String, origin: String, sequences: [[String]]) -> [CoreCandidate] {
                let hasSeparators: Bool = text.count != origin.count
                let candidates = match(schemes: sequences, hasSeparators: hasSeparators)
                guard !hasSeparators else { return candidates }
                guard let firstCandidate = candidates.first else { return candidates }
                let firstInputCount: Int = firstCandidate.input.count
                guard firstInputCount != text.count else { return candidates }
                let tailText: String = String(text.dropFirst(firstInputCount))
                let tailSchemes: [[String]] = Splitter.engineSplit(tailText)
                let tailCandidates = match(schemes: tailSchemes, hasSeparators: false)
                guard let backCandidate = tailCandidates.first else { return candidates }
                let offset: Int = (firstCandidate.text.count < 3) ? 3 : 2
                let qualified = candidates.enumerated().filter({ $0.offset < offset && $0.element.input.count == firstInputCount })
                let combines = qualified.map({ $0.element + backCandidate })
                return combines + candidates
        }
        private static func processPartial(text: String, origin: String, sequences: [[String]]) -> [CoreCandidate] {
                let hasSeparators: Bool = text.count != origin.count
                let candidates: [CoreCandidate] = match(schemes: sequences, hasSeparators: hasSeparators)
                lazy var fallback: [CoreCandidate] = match(for: text) + prefix(match: text, count: 5) + candidates + shortcut(for: text)
                guard !hasSeparators else { return fallback }
                guard let firstCandidate: CoreCandidate = candidates.first else { return fallback }
                let firstInputCount: Int = firstCandidate.input.count
                guard firstInputCount != text.count else { return fallback }
                let tailText: String = String(text.dropFirst(firstInputCount))
                if let tailOne: CoreCandidate = prefix(match: tailText, count: 1).first {
                        let combine: CoreCandidate = firstCandidate + tailOne
                        return match(for: text) + prefix(match: text, count: 5) + [combine] + candidates + shortcut(for: text)
                }
                let tailSyllables: [String] = Splitter.peekSplit(tailText)
                guard !(tailSyllables.isEmpty) else { return fallback }
                var concatenated: [CoreCandidate] = []
                let hasTailCandidate: Bool = {
                        let syllablesText = tailSyllables.joined()
                        let difference: Int = tailText.count - syllablesText.count
                        guard difference > 1 else { return false }
                        let syllablesPlusOne = tailText.dropLast(difference - 1)
                        guard let one = prefix(match: String(syllablesPlusOne), count: 1).first else { return false }
                        let combine: CoreCandidate = firstCandidate + one
                        concatenated.append(combine)
                        return true
                }()
                if !hasTailCandidate {
                        for (index, _) in tailSyllables.enumerated().reversed() {
                                let someSyllables: String = tailSyllables[0...index].joined()
                                if let one: CoreCandidate = matchWithLimitCount(for: someSyllables, count: 1).first {
                                        let combine: CoreCandidate = firstCandidate + one
                                        concatenated.append(combine)
                                        break
                                }
                        }
                }
                return match(for: text) + prefix(match: text, count: 5) + concatenated + candidates + shortcut(for: text)
        }
        private static func match(schemes: [[String]], hasSeparators: Bool) -> [CoreCandidate] {
                let matches = schemes.map({ matchWithRowID(for: $0.joined()) }).joined()
                let sorted = matches.sorted { $0.candidate.text.count == $1.candidate.text.count && ($1.row - $0.row) > 50000 }
                let candidates: [CoreCandidate] = sorted.map({ $0.candidate })
                guard hasSeparators else { return candidates }
                let firstSyllable: String = schemes.first?.first ?? "X"
                let filtered: [CoreCandidate] = candidates.filter { candidate in
                        let firstRomanization: String = candidate.romanization.components(separatedBy: String.space).first ?? "Y"
                        return firstSyllable == firstRomanization.removedTones()
                }
                return filtered
        }
}


private extension Lychee {

        // CREATE TABLE imetable(word TEXT NOT NULL, romanization TEXT NOT NULL, ping INTEGER NOT NULL, shortcut INTEGER NOT NULL, prefix INTEGER NOT NULL);

        static func shortcut(for text: String, count: Int = 100) -> [CoreCandidate] {
                guard !text.isEmpty else { return [] }
                let textHash: Int = text.replacingOccurrences(of: "y", with: "j").hash
                var candidates: [CoreCandidate] = []
                let queryString = "SELECT word, romanization FROM imetable WHERE shortcut = \(textHash) LIMIT \(count);"
                var queryStatement: OpaquePointer? = nil
                if sqlite3_prepare_v2(Lychee.database, queryString, -1, &queryStatement, nil) == SQLITE_OK {
                        while sqlite3_step(queryStatement) == SQLITE_ROW {
                                let word: String = String(cString: sqlite3_column_text(queryStatement, 0))
                                let romanization: String = String(cString: sqlite3_column_text(queryStatement, 1))
                                let candidate: CoreCandidate = CoreCandidate(text: word, romanization: romanization, input: text)
                                candidates.append(candidate)
                        }
                }
                sqlite3_finalize(queryStatement)
                return candidates
        }

        static func match(for text: String) -> [CoreCandidate] {
                guard !text.isEmpty else { return [] }
                var candidates: [CoreCandidate] = []
                let tones: String = text.tones
                let hasTones: Bool = !tones.isEmpty
                let ping: String = hasTones ? text.removedTones() : text
                let queryString = "SELECT word, romanization FROM imetable WHERE ping = \(ping.hash);"
                var queryStatement: OpaquePointer? = nil
                if sqlite3_prepare_v2(Lychee.database, queryString, -1, &queryStatement, nil) == SQLITE_OK {
                        while sqlite3_step(queryStatement) == SQLITE_ROW {
                                let word: String = String(cString: sqlite3_column_text(queryStatement, 0))
                                let romanization: String = String(cString: sqlite3_column_text(queryStatement, 1))
                                if !hasTones || tones == romanization.tones || (tones.count == 1 && text.last == romanization.last) {
                                        let candidate: CoreCandidate = CoreCandidate(text: word, romanization: romanization, input: text)
                                        candidates.append(candidate)
                                }
                        }
                }
                sqlite3_finalize(queryStatement)
                return candidates
        }
        static func matchWithLimitCount(for text: String, count: Int) -> [CoreCandidate] {
                guard !text.isEmpty else { return [] }
                var candidates: [CoreCandidate] = []
                let tones: String = text.tones
                let hasTones: Bool = !tones.isEmpty
                let ping: String = hasTones ? text.removedTones() : text
                let queryString = "SELECT word, romanization FROM imetable WHERE ping = \(ping.hash) LIMIT \(count);"
                var queryStatement: OpaquePointer? = nil
                if sqlite3_prepare_v2(Lychee.database, queryString, -1, &queryStatement, nil) == SQLITE_OK {
                        while sqlite3_step(queryStatement) == SQLITE_ROW {
                                let word: String = String(cString: sqlite3_column_text(queryStatement, 0))
                                let romanization: String = String(cString: sqlite3_column_text(queryStatement, 1))
                                if !hasTones || tones == romanization.tones || (tones.count == 1 && text.last == romanization.last) {
                                        let candidate: CoreCandidate = CoreCandidate(text: word, romanization: romanization, input: text)
                                        candidates.append(candidate)
                                }
                        }
                }
                sqlite3_finalize(queryStatement)
                return candidates
        }
        static func matchWithRowID(for text: String) -> [RowCandidate] {
                guard !text.isEmpty else { return [] }
                var rowCandidates: [RowCandidate] = []
                let tones: String = text.tones
                let hasTones: Bool = !tones.isEmpty
                let ping: String = hasTones ? text.removedTones() : text
                let queryString = "SELECT rowid, word, romanization FROM imetable WHERE ping = \(ping.hash);"
                var queryStatement: OpaquePointer? = nil
                if sqlite3_prepare_v2(Lychee.database, queryString, -1, &queryStatement, nil) == SQLITE_OK {
                        while sqlite3_step(queryStatement) == SQLITE_ROW {
                                let rowid: Int = Int(sqlite3_column_int64(queryStatement, 0))
                                let word: String = String(cString: sqlite3_column_text(queryStatement, 1))
                                let romanization: String = String(cString: sqlite3_column_text(queryStatement, 2))
                                if !hasTones || tones == romanization.tones || (tones.count == 1 && text.last == romanization.last) {
                                        let candidate: CoreCandidate = CoreCandidate(text: word, romanization: romanization, input: text)
                                        let rowCandidate: RowCandidate = (candidate: candidate, row: rowid)
                                        rowCandidates.append(rowCandidate)
                                }
                        }
                }
                sqlite3_finalize(queryStatement)
                return rowCandidates
        }

        static func prefix(match text: String, count: Int = 100) -> [CoreCandidate] {
                guard !text.isEmpty else { return [] }
                var candidates: [CoreCandidate] = []
                let queryString = "SELECT word, romanization FROM imetable WHERE prefix = \(text.hash) LIMIT \(count);"
                var queryStatement: OpaquePointer? = nil
                if sqlite3_prepare_v2(Lychee.database, queryString, -1, &queryStatement, nil) == SQLITE_OK {
                        while sqlite3_step(queryStatement) == SQLITE_ROW {
                                let word: String = String(cString: sqlite3_column_text(queryStatement, 0))
                                let romanization: String = String(cString: sqlite3_column_text(queryStatement, 1))
                                let candidate: CoreCandidate = CoreCandidate(text: word, romanization: romanization, input: text)
                                candidates.append(candidate)
                        }
                }
                sqlite3_finalize(queryStatement)
                return candidates
        }
}

