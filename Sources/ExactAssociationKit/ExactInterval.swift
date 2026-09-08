import AssociationTransportKit
import Foundation

/// How an interval around an odds ratio was arrived at.
public enum IntervalMethod: Sendable, Equatable {

    /// Inverting two one-sided exact conditional tests. Guaranteed coverage, and wider than nominal.
    case exactConditional

    /// The same inversion with the observed table counted half in each tail. Coverage on average.
    case midP

    /// A normal interval on the log scale using Woolf's standard error. Asymptotic.
    case woolf

    /// A short name for a report.
    public var label: String {
        switch self {
        case .exactConditional: return "exact"
        case .midP: return "mid-p"
        case .woolf: return "Woolf"
        }
    }
}

/// An interval for a block's odds ratio, on the ratio scale.
///
/// `lower` may be exactly `0` and `upper` may be infinite, and both are answers rather than
/// failures: a block sitting at the edge of its own support bounds the odds ratio on one side only.
/// An asymptotic method never produces either, which is not because it knows more.
public struct ExactInterval: Sendable, Equatable {

    /// The lower end. Zero when the data bound the odds ratio from above only.
    public let lower: Double

    /// The upper end. Infinite when the data bound it from below only.
    public let upper: Double

    /// How it was built.
    public let method: IntervalMethod

    init(lower: Double, upper: Double, method: IntervalMethod) {
        self.lower = lower
        self.upper = upper
        self.method = method
    }

    /// Rebuilds the Woolf interval `reading` already carries, so the two can be compared as one type.
    public init(_ reading: StructureReading) {
        self.init(lower: reading.lower, upper: reading.upper, method: .woolf)
    }

    /// `true` when the interval covers `1.0`, so the block is not distinguishable from independence.
    public var coversIndependence: Bool { lower <= 1 && 1 <= upper }

    /// `true` when both ends are finite and positive.
    public var isBounded: Bool { lower > 0 && upper.isFinite }

    /// The interval's width on the log scale, which is where the two methods are comparable.
    public var logWidth: Double { Foundation.log(upper) - Foundation.log(lower) }

    /// The multiplicative factor between the ends, infinite when either end is unbounded.
    public var factor: Double { isBounded ? upper / lower : .infinity }
}
