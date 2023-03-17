import Foundation
import SQLite3

private struct RowCandidate: Hashable {
        let candidate: Candidate
        let row: Int
        let isExactlyMatch: Bool
}

private extension Array where Element == RowCandidate {
        func sorted() -> [RowCandidate] {
                return self.sorted(by: { (lhs, rhs) -> Bool in
                        let shouldCompare: Bool = !lhs.isExactlyMatch && !rhs.isExactlyMatch
                        guard shouldCompare else { return lhs.isExactlyMatch && !rhs.isExactlyMatch }
                        let lhsTextCount: Int = lhs.candidate.text.count
                        let rhsTextCount: Int = rhs.candidate.text.count
                        guard lhsTextCount >= rhsTextCount else { return false }
                        return (rhs.row - lhs.row) > 50000
                })
        }
}

extension Engine {

        public static func suggest(for text: String, segmentation: Segmentation) -> [Candidate] {
                switch text.count {
                case 0:
                        return []
                case 1:
                        return shortcut(for: text)
                default:
                        return fetch(text: text, segmentation: segmentation)
                }
        }

        private static func fetch(text: String, segmentation: Segmentation) -> [CoreCandidate] {
                let textWithoutSeparators: String = text.filter({ !($0.isSeparator) })
                guard let bestScheme: SyllableScheme = segmentation.first, !bestScheme.isEmpty else {
                        return processVerbatim(textWithoutSeparators)
                }
                let convertedText = textWithoutSeparators.replacingOccurrences(of: "(?<!c|s|j|z)yu(?!k|m|ng)", with: "jyu", options: .regularExpression)
                if bestScheme.length == convertedText.count {
                        return process(text: convertedText, origin: text, sequences: segmentation)
                } else {
                        return processPartial(text: textWithoutSeparators, origin: text, segmentation: segmentation)
                }
        }
        private static func processVerbatim(_ text: String) -> [CoreCandidate] {
                let rounds = (0..<text.count).map { number -> [CoreCandidate] in
                        let leading: String = String(text.dropLast(number))
                        return match(for: leading) + shortcut(for: leading)
                }
                return rounds.flatMap({ $0 }).uniqued()
        }
        private static func process(text: String, origin: String, sequences: [[String]]) -> [CoreCandidate] {
                let hasSeparators: Bool = text.count != origin.count
                let candidates = match(schemes: sequences, hasSeparators: hasSeparators, fullTextCount: origin.count)
                guard !hasSeparators else { return candidates }
                let fullProcessed: [CoreCandidate] = match(for: text) + shortcut(for: text)
                let backup: [CoreCandidate] = processVerbatim(text)
                let fallback: [CoreCandidate] = fullProcessed + candidates + backup
                guard let firstCandidate = candidates.first else { return fallback }
                let firstInputCount: Int = firstCandidate.input.count
                guard firstInputCount != text.count else { return fallback }
                let tailText: String = String(text.dropFirst(firstInputCount))
                let tailSegmentation: Segmentation = Segmentor.engineSegment(tailText)
                let hasSchemes: Bool = !(tailSegmentation.first?.isEmpty ?? true)
                guard hasSchemes else { return fallback }
                let tailCandidates: [CoreCandidate] = (match(for: tailText) + shortcut(for: tailText) + match(schemes: tailSegmentation, hasSeparators: false)).uniqued()
                guard !(tailCandidates.isEmpty) else { return fallback }
                let qualified = candidates.enumerated().filter({ $0.offset < 3 && $0.element.input.count == firstInputCount })
                let combines = tailCandidates.map { tail -> [CoreCandidate] in
                        return qualified.map({ $0.element + tail })
                }
                let concatenated: [CoreCandidate] = combines.flatMap({ $0 }).enumerated().filter({ $0.offset < 4 }).map(\.element)
                return fullProcessed + concatenated + candidates + backup
        }
        private static func processPartial(text: String, origin: String, segmentation: Segmentation) -> [CoreCandidate] {
                let hasSeparators: Bool = text.count != origin.count
                let candidates = match(schemes: segmentation, hasSeparators: hasSeparators, fullTextCount: origin.count)
                guard !hasSeparators else { return candidates }
                let fullProcessed: [CoreCandidate] = match(for: text) + shortcut(for: text)
                let backup: [CoreCandidate] = processVerbatim(text)
                let fallback: [CoreCandidate] = fullProcessed + candidates + backup
                guard let firstCandidate = candidates.first else { return fallback }
                let firstInputCount: Int = firstCandidate.input.count
                guard firstInputCount != text.count else { return fallback }
                let anchorsArray: [String] = segmentation.map({ scheme -> String in
                        let last = text.dropFirst(scheme.length).first
                        let schemeAnchors = scheme.map({ $0.first })
                        let anchors = (schemeAnchors + [last]).compactMap({ $0 })
                        return String(anchors)
                })
                let prefixes: [CoreCandidate] = anchorsArray.map({ shortcut(for: $0) }).flatMap({ $0 })
                        .filter({ $0.romanization.removedSpacesTones().hasPrefix(text) })
                        .map({ CoreCandidate(text: $0.text, romanization: $0.romanization, input: text) })
                guard prefixes.isEmpty else { return fullProcessed + prefixes + candidates + backup }
                let tailText: String = String(text.dropFirst(firstInputCount))
                let tailCandidates = processVerbatim(tailText)
                        .filter({ item -> Bool in
                                let hasText: Bool = item.romanization.removedSpacesTones().hasPrefix(tailText)
                                guard !hasText else { return true }
                                let anchors = item.romanization.split(separator: " ").map({ $0.first }).compactMap({ $0 })
                                return anchors == tailText.map({ $0 })
                        })
                        .map({ CoreCandidate(text: $0.text, romanization: $0.romanization, input: tailText) })
                guard !(tailCandidates.isEmpty) else { return fallback }
                let qualified = candidates.enumerated().filter({ $0.offset < 3 && $0.element.input.count == firstInputCount })
                let combines = tailCandidates.map { tail -> [CoreCandidate] in
                        return qualified.map({ $0.element + tail })
                }
                let concatenated: [CoreCandidate] = combines.flatMap({ $0 }).enumerated().filter({ $0.offset < 4 }).map(\.element)
                return fullProcessed + concatenated + candidates + backup
        }
        private static func match(schemes: [[String]], hasSeparators: Bool, fullTextCount: Int = -1) -> [CoreCandidate] {
                let matches = schemes.map { scheme -> [RowCandidate] in
                        let joinedText = scheme.joined()
                        let isExactlyMatch: Bool = joinedText.count == fullTextCount
                        return matchRowCandidate(for: joinedText, isExactlyMatch: isExactlyMatch)
                }
                let candidates: [CoreCandidate] = matches.flatMap({ $0 }).sorted().map(\.candidate)
                guard hasSeparators else { return candidates }
                let firstSyllable: String = schemes.first?.first ?? "X"
                let filtered: [CoreCandidate] = candidates.filter { candidate in
                        let firstRomanization: String = candidate.romanization.components(separatedBy: String.space).first ?? "Y"
                        return firstSyllable == firstRomanization.removedTones()
                }
                return filtered
        }
}

private extension Engine {

        // CREATE TABLE lexicontable(word TEXT NOT NULL, romanization TEXT NOT NULL, shortcut INTEGER NOT NULL, ping INTEGER NOT NULL);

        static func shortcut(for text: String, count: Int = 100) -> [CoreCandidate] {
                guard !text.isEmpty else { return [] }
                let textHash: Int = text.replacingOccurrences(of: "y", with: "j").hash
                var candidates: [CoreCandidate] = []
                let query = "SELECT word, romanization FROM lexicontable WHERE shortcut = \(textHash) LIMIT \(count);"
                var statement: OpaquePointer? = nil
                if sqlite3_prepare_v2(Engine.database, query, -1, &statement, nil) == SQLITE_OK {
                        while sqlite3_step(statement) == SQLITE_ROW {
                                let word: String = String(cString: sqlite3_column_text(statement, 0))
                                let romanization: String = String(cString: sqlite3_column_text(statement, 1))
                                let candidate = CoreCandidate(text: word, romanization: romanization, input: text)
                                candidates.append(candidate)
                        }
                }
                sqlite3_finalize(statement)
                return candidates
        }

        static func match(for text: String) -> [CoreCandidate] {
                let tones: String = text.tones
                let hasTones: Bool = !tones.isEmpty
                let ping: String = hasTones ? text.removedTones() : text
                guard !(ping.isEmpty) else { return [] }
                let candidates: [CoreCandidate] = queryPing(for: text, ping: ping)
                guard hasTones else { return candidates }
                let sameTones = candidates.filter({ $0.romanization.tones == tones })
                guard sameTones.isEmpty else { return sameTones }
                let filtered = candidates.filter({ item -> Bool in
                        let syllables = item.romanization.split(separator: " ")
                        let rawSyllables = item.romanization.removedTones().split(separator: " ")
                        guard rawSyllables.uniqued().count == syllables.count else { return false }
                        let times: Int = syllables.reduce(0, { $0 + (text.contains($1) ? 1 : 0) })
                        return times == tones.count
                })
                return filtered
        }
        private static func queryPing(for text: String, ping: String) -> [CoreCandidate] {
                var candidates: [CoreCandidate] = []
                let query = "SELECT word, romanization FROM lexicontable WHERE ping = \(ping.hash);"
                var statement: OpaquePointer? = nil
                if sqlite3_prepare_v2(Engine.database, query, -1, &statement, nil) == SQLITE_OK {
                        while sqlite3_step(statement) == SQLITE_ROW {
                                let word: String = String(cString: sqlite3_column_text(statement, 0))
                                let romanization: String = String(cString: sqlite3_column_text(statement, 1))
                                let candidate = CoreCandidate(text: word, romanization: romanization, input: text)
                                candidates.append(candidate)
                        }
                }
                sqlite3_finalize(statement)
                return candidates
        }

        static func matchRowCandidate(for text: String, isExactlyMatch: Bool) -> [RowCandidate] {
                let tones: String = text.tones
                let hasTones: Bool = !tones.isEmpty
                let ping: String = hasTones ? text.removedTones() : text
                guard !(ping.isEmpty) else { return [] }
                let candidates = queryRowCandidate(for: text, ping: ping, isExactlyMatch: isExactlyMatch)
                guard hasTones else { return candidates }
                let sameTones = candidates.filter({ $0.candidate.romanization.tones == tones })
                guard sameTones.isEmpty else { return sameTones }
                let filtered = candidates.filter({ item -> Bool in
                        let syllables = item.candidate.romanization.split(separator: " ")
                        let rawSyllables = item.candidate.romanization.removedTones().split(separator: " ")
                        guard rawSyllables.uniqued().count == syllables.count else { return false }
                        let times: Int = syllables.reduce(0, { $0 + (text.contains($1) ? 1 : 0) })
                        return times == tones.count
                })
                return filtered
        }
        private static func queryRowCandidate(for text: String, ping: String, isExactlyMatch: Bool) -> [RowCandidate] {
                var rowCandidates: [RowCandidate] = []
                let query = "SELECT rowid, word, romanization FROM lexicontable WHERE ping = \(ping.hash);"
                var statement: OpaquePointer? = nil
                if sqlite3_prepare_v2(Engine.database, query, -1, &statement, nil) == SQLITE_OK {
                        while sqlite3_step(statement) == SQLITE_ROW {
                                let rowid: Int = Int(sqlite3_column_int64(statement, 0))
                                let word: String = String(cString: sqlite3_column_text(statement, 1))
                                let romanization: String = String(cString: sqlite3_column_text(statement, 2))
                                let candidate: CoreCandidate = CoreCandidate(text: word, romanization: romanization, input: text)
                                let rowCandidate: RowCandidate = RowCandidate(candidate: candidate, row: rowid, isExactlyMatch: isExactlyMatch)
                                rowCandidates.append(rowCandidate)
                        }
                }
                sqlite3_finalize(statement)
                return rowCandidates
        }
}
