import Foundation

/// Everything this package refuses to do rather than guess at.
public enum ExactAssociationError: Error, Equatable, Sendable {

    /// A block was handed a negative count.
    case negativeCount(position: String, count: Int)

    /// A block whose margins leave the conditional distribution a single point.
    ///
    /// A row or column total of zero pins the corner cell at one value, so the conditional
    /// distribution given the margins has support of size one and carries no information about
    /// the odds ratio at all. Every method here — exact, mid-p, Woolf — would return the whole
    /// line. Saying so is more useful than returning it.
    case degenerateSupport(rowTotal: Int, otherRowTotal: Int, columnTotal: Int)

    /// A confidence level outside `(0, 1)`.
    case alphaOutOfRange(Double)

    /// A block index that does not name a two-by-two block of the panel it was asked for.
    case blockOutOfRange(row: Int, column: Int, categoryCount: Int)

    /// An exact reading and an asymptotic one drawn at different levels.
    ///
    /// The comparison this package exists for is between two intervals around the same estimand at
    /// the same level. Comparing a 95% exact interval to a 99% Woolf one produces a width ratio
    /// that means nothing, and the mistake is invisible in the output. It is refused instead.
    case confidenceLevelMismatch(exact: String, asymptotic: String)

    /// A ledger key that was never recorded.
    case unknownAuditKey(String)
}

extension ExactAssociationError: CustomStringConvertible {

    public var description: String {
        switch self {
        case let .negativeCount(position, count):
            return "count at \(position) is \(count); a block is made of whole non-negative items"
        case let .degenerateSupport(rowTotal, otherRowTotal, columnTotal):
            return """
                margins \(rowTotal)/\(otherRowTotal) by \(columnTotal) pin the block to one table; \
                no method can read an odds ratio off it
                """
        case let .alphaOutOfRange(alpha):
            return "confidence alpha \(alpha) is not strictly between 0 and 1"
        case let .blockOutOfRange(row, column, categoryCount):
            return "block (\(row), \(column)) is not a two-by-two block of a \(categoryCount)-category panel"
        case let .confidenceLevelMismatch(exact, asymptotic):
            return "exact reading at \(exact) cannot be compared with an asymptotic one at \(asymptotic)"
        case let .unknownAuditKey(key):
            return "no audit recorded under \(key)"
        }
    }
}
