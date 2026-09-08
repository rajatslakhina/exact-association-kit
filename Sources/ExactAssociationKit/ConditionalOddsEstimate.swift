import Foundation

/// What the conditional likelihood says a block's odds ratio is.
///
/// The sample odds ratio `ad / bc` is the unconditional maximum likelihood estimate, and it is
/// biased away from `1` — the smaller the block, the further. The conditional estimate is the odds
/// ratio whose conditional distribution has the observed count as its mean, which is the estimate
/// the exact interval is actually built around. Quoting `ad / bc` and then bracketing it with an
/// exact interval mixes two estimators, and on a small block the point can sit noticeably nearer
/// the edge of its own interval than it should.
///
/// The two unbounded cases are not failures. A block whose top-left count sits at the smallest
/// value its margins allow has a conditional likelihood that increases all the way down; there is
/// no interior maximum, and reporting one would be inventing it.
public enum ConditionalOddsEstimate: Sendable, Equatable {

    /// The observed count is the smallest its margins allow, so the likelihood is maximised at zero.
    case zero

    /// An interior maximum.
    case finite(Double)

    /// The observed count is the largest its margins allow, so the likelihood never turns over.
    case unbounded

    /// The estimate as a number, or `nil` at either boundary.
    public var value: Double? {
        guard case let .finite(value) = self else { return nil }
        return value
    }

    /// A short name for a report.
    public var label: String {
        switch self {
        case .zero: return "0"
        case let .finite(value): return Formatting.decimal(value)
        case .unbounded: return "inf"
        }
    }

    /// Reads the estimate off `block`.
    ///
    /// - Throws: ``ExactAssociationError/degenerateSupport(rowTotal:otherRowTotal:columnTotal:)``.
    public static func of(_ block: ExactBlock) throws -> ConditionalOddsEstimate {
        let distribution = try block.conditionalDistribution()
        if block.a == distribution.lowerSupport { return .zero }
        if block.a == distribution.upperSupport { return .unbounded }
        let target = Double(block.a)
        return .finite(Foundation.exp(RootSolver.crossing(of: target) { distribution.mean(atLogOdds: $0) }))
    }
}
