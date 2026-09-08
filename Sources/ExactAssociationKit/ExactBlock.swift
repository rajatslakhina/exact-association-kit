import AssociationTransportKit
import Foundation

/// One two-by-two block of counts, in the order every local odds ratio in this series reads them.
///
/// `a` and `b` are the top row, `c` and `d` the bottom, and the sample odds ratio is `ad / bc`.
/// The counts are integers and stay integers: exact conditional inference is a statement about the
/// discrete distribution of `a` given the margins, and a block of real numbers has no such
/// distribution. That is the practical difference between this package and every reading the
/// series has taken so far — an asymptotic method will happily accept `36.5`, which is how a
/// correction for empty cells becomes invisible.
public struct ExactBlock: Sendable, Equatable, Hashable {

    /// Top-left count.
    public let a: Int

    /// Top-right count.
    public let b: Int

    /// Bottom-left count.
    public let c: Int

    /// Bottom-right count.
    public let d: Int

    /// - Throws: ``ExactAssociationError/negativeCount(position:count:)``.
    public init(a: Int, b: Int, c: Int, d: Int) throws {
        for (name, count) in [("a", a), ("b", b), ("c", c), ("d", d)] where count < 0 {
            throw ExactAssociationError.negativeCount(position: name, count: count)
        }
        self.a = a
        self.b = b
        self.c = c
        self.d = d
    }

    /// Reads the block whose top-left corner is `block` off `panel`, without correcting anything.
    ///
    /// - Throws: ``ExactAssociationError/blockOutOfRange(row:column:categoryCount:)``.
    public init(panel: ObservedPanel, block: PanelCell) throws {
        let limit = panel.categoryCount - 1
        guard block.row >= 0, block.column >= 0, block.row < limit, block.column < limit else {
            throw ExactAssociationError.blockOutOfRange(
                row: block.row, column: block.column, categoryCount: panel.categoryCount
            )
        }
        let cells = panel.cells(of: block)
        try self.init(a: cells[0], b: cells[1], c: cells[2], d: cells[3])
    }

    /// The top row's total, which the conditional distribution holds fixed.
    public var rowTotal: Int { a + b }

    /// The bottom row's total.
    public var otherRowTotal: Int { c + d }

    /// The left column's total.
    public var columnTotal: Int { a + c }

    /// The right column's total.
    public var otherColumnTotal: Int { b + d }

    /// How many items the block contains.
    public var itemCount: Int { a + b + c + d }

    /// `ad / bc`, or `nil` when a zero count leaves it undefined or infinite.
    ///
    /// The series has been reaching for a correction at this point. Nothing downstream of here
    /// needs one: the conditional estimate in ``ConditionalOddsEstimate`` is defined for every
    /// block this type accepts, including blocks with three empty cells.
    public var sampleOddsRatio: Double? {
        guard b > 0, c > 0 else { return nil }
        return Double(a) * Double(d) / (Double(b) * Double(c))
    }

    /// `true` when some cell of the block is empty.
    public var hasEmptyCell: Bool { a == 0 || b == 0 || c == 0 || d == 0 }

    /// The conditional distribution of `a` given this block's margins.
    ///
    /// - Throws: ``ExactAssociationError/degenerateSupport(rowTotal:otherRowTotal:columnTotal:)``.
    public func conditionalDistribution() throws -> NoncentralHypergeometric {
        try NoncentralHypergeometric(
            rowTotal: rowTotal, otherRowTotal: otherRowTotal, columnTotal: columnTotal
        )
    }
}
