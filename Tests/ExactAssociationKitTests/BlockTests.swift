import AssociationTransportKit
import Testing
@testable import ExactAssociationKit

@Suite("Blocks")
struct BlockTests {

    static let split = try! ExactBlock(a: 4, b: 1, c: 1, d: 6)
    static let corner = try! ExactBlock(a: 2, b: 0, c: 0, d: 5)

    @Test("margins and totals are read off the four counts")
    func margins() {
        let block = Self.split
        #expect(block.rowTotal == 5)
        #expect(block.otherRowTotal == 7)
        #expect(block.columnTotal == 5)
        #expect(block.otherColumnTotal == 7)
        #expect(block.itemCount == 12)
    }

    @Test("a negative count is refused rather than absorbed")
    func negative() {
        #expect(throws: ExactAssociationError.negativeCount(position: "c", count: -1)) {
            _ = try ExactBlock(a: 1, b: 2, c: -1, d: 3)
        }
        #expect(throws: ExactAssociationError.negativeCount(position: "a", count: -4)) {
            _ = try ExactBlock(a: -4, b: 2, c: 1, d: 3)
        }
    }

    @Test("a block reads off a panel by its top-left corner, uncorrected")
    func fromPanel() throws {
        let panel = try ObservedPanel(counts: [[4, 1], [1, 6]])
        let block = try ExactBlock(panel: panel, block: PanelCell(row: 0, column: 0))
        #expect(block == Self.split)
    }

    @Test("a corner that is not a two-by-two block is refused")
    func outOfRange() throws {
        let panel = try ObservedPanel(counts: [[4, 1], [1, 6]])
        #expect(throws: ExactAssociationError.blockOutOfRange(row: 1, column: 0, categoryCount: 2)) {
            _ = try ExactBlock(panel: panel, block: PanelCell(row: 1, column: 0))
        }
        #expect(throws: ExactAssociationError.blockOutOfRange(row: 0, column: -1, categoryCount: 2)) {
            _ = try ExactBlock(panel: panel, block: PanelCell(row: 0, column: -1))
        }
    }

    @Test("the sample odds ratio is defined only when no denominator is empty")
    func sampleRatio() {
        #expect(Self.split.sampleOddsRatio == 24)
        #expect(Self.split.hasEmptyCell == false)
        #expect(Self.corner.sampleOddsRatio == nil)
        #expect(Self.corner.hasEmptyCell)
    }
}
