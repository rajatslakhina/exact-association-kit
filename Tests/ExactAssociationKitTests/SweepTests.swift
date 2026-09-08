import Foundation
import Testing
@testable import ExactAssociationKit

/// Claims about the methods themselves, checked by enumeration rather than asserted in a comment.
@Suite("Sweeps")
struct SweepTests {

    /// The largest table the sweep enumerates. Every two-by-two table with at most this many items
    /// and no empty cell is visited, which is a few thousand of them.
    static let itemLimit = 20

    static let multiplier = 1.959963984540054

    static func woolf(_ block: ExactBlock) -> ExactInterval {
        let ratio = Double(block.a) * Double(block.d) / (Double(block.b) * Double(block.c))
        let error = (1.0 / Double(block.a) + 1 / Double(block.b) + 1 / Double(block.c) + 1 / Double(block.d))
            .squareRoot()
        return ExactInterval(
            lower: exp(log(ratio) - multiplier * error),
            upper: exp(log(ratio) + multiplier * error),
            method: .woolf
        )
    }

    static func tables(_ limit: Int) -> [ExactBlock] {
        var blocks: [ExactBlock] = []
        for rowTotal in 1..<limit {
            for otherRowTotal in 1...(limit - rowTotal) {
                let total = rowTotal + otherRowTotal
                for columnTotal in 1..<total {
                    let lower = max(0, columnTotal - otherRowTotal)
                    let upper = min(rowTotal, columnTotal)
                    guard lower < upper else { continue }
                    for count in (lower + 1)..<upper {
                        guard
                            let block = try? ExactBlock(
                                a: count, b: rowTotal - count,
                                c: columnTotal - count, d: otherRowTotal - (columnTotal - count)
                            ),
                            !block.hasEmptyCell
                        else { continue }
                        blocks.append(block)
                    }
                }
            }
        }
        return blocks
    }

    @Test("the asymptotic interval is never the wider of the two")
    func woolfIsNeverWider() throws {
        let blocks = Self.tables(Self.itemLimit)
        #expect(blocks.count > 1000)
        var narrowest = Double.infinity
        for block in blocks {
            let reading = try ExactReading.of(block)
            let ratio = reading.exact.logWidth / Self.woolf(block).logWidth
            #expect(ratio >= 1)
            narrowest = min(narrowest, ratio)
        }
        // Not "sometimes narrower": the closest any Woolf interval in this range gets to its own
        // exact counterpart is eighteen per cent short of it, on the log scale.
        #expect(abs(narrowest - 1.1820287012990223) < 1e-9)
    }

    @Test("the exact interval covers one exactly when neither one-sided tail is small")
    func inversionIsConsistent() throws {
        for block in Self.tables(12) {
            let reading = try ExactReading.of(block)
            let distribution = try block.conditionalDistribution()
            let above = distribution.probabilityAtOrAbove(block.a, atLogOdds: 0)
            let below = distribution.probabilityAtOrBelow(block.a, atLogOdds: 0)
            #expect(reading.exact.coversIndependence == (min(above, below) > 0.025))
        }
    }

    @Test("the mid-p interval never reaches outside the exact one")
    func midPIsInside() throws {
        for block in Self.tables(12) {
            let reading = try ExactReading.of(block)
            #expect(reading.midP.lower >= reading.exact.lower)
            #expect(reading.midP.upper <= reading.exact.upper)
        }
    }
}
