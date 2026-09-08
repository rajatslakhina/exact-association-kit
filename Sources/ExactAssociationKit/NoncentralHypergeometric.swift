import Foundation

/// The distribution of a block's top-left count once its margins are held fixed.
///
/// Fisher's noncentral hypergeometric distribution. Conditioning on all four margins removes every
/// nuisance parameter from a two-by-two table and leaves exactly one: the odds ratio, which enters
/// as `psi^a`. That is the whole reason exact inference for an odds ratio is possible where it is
/// not for most quantities — the conditional likelihood is a one-parameter family over a finite
/// support, so a probability can be summed rather than approximated.
///
/// Every computation here is done on the log scale and normalised by its own maximum. The binomial
/// coefficients on a panel of a few hundred items overflow a `Double` on their own, and the
/// interval search visits odds ratios far enough from `1` that `psi^a` overflows long before the
/// coefficients do.
public struct NoncentralHypergeometric: Sendable, Equatable {

    /// The top row's total.
    public let rowTotal: Int

    /// The bottom row's total.
    public let otherRowTotal: Int

    /// The left column's total.
    public let columnTotal: Int

    /// The smallest top-left count these margins allow.
    public let lowerSupport: Int

    /// The largest top-left count these margins allow.
    public let upperSupport: Int

    private let logCoefficients: [Double]

    /// - Throws: ``ExactAssociationError/degenerateSupport(rowTotal:otherRowTotal:columnTotal:)``.
    public init(rowTotal: Int, otherRowTotal: Int, columnTotal: Int) throws {
        let lower = max(0, columnTotal - otherRowTotal)
        let upper = min(rowTotal, columnTotal)
        guard lower < upper else {
            throw ExactAssociationError.degenerateSupport(
                rowTotal: rowTotal, otherRowTotal: otherRowTotal, columnTotal: columnTotal
            )
        }
        self.rowTotal = rowTotal
        self.otherRowTotal = otherRowTotal
        self.columnTotal = columnTotal
        self.lowerSupport = lower
        self.upperSupport = upper
        self.logCoefficients = (lower...upper).map { value in
            Self.logChoose(rowTotal, value) + Self.logChoose(otherRowTotal, columnTotal - value)
        }
    }

    /// Every top-left count these margins allow.
    public var support: ClosedRange<Int> { lowerSupport...upperSupport }

    /// How many tables the margins allow, which bounds how fine a p-value can be.
    ///
    /// A discrete distribution over `n` points cannot produce a tail probability between its
    /// jumps, and that is the entire source of the exact test's conservatism. A block with three
    /// tables in its support has three attainable one-sided p-values.
    public var supportSize: Int { upperSupport - lowerSupport + 1 }

    /// The probability of each attainable count at odds ratio `exp(logOdds)`.
    public func probabilities(atLogOdds logOdds: Double) -> [Double] {
        var scaled = [Double](repeating: 0, count: logCoefficients.count)
        var largest = -Double.infinity
        for index in logCoefficients.indices {
            let value = logCoefficients[index] + Double(lowerSupport + index) * logOdds
            scaled[index] = value
            largest = Swift.max(largest, value)
        }
        var total = 0.0
        for index in scaled.indices {
            let weight = Foundation.exp(scaled[index] - largest)
            scaled[index] = weight
            total += weight
        }
        for index in scaled.indices {
            scaled[index] /= total
        }
        return scaled
    }

    /// The expected top-left count at odds ratio `exp(logOdds)`.
    ///
    /// Strictly increasing in `logOdds`, from ``lowerSupport`` to ``upperSupport``. That monotonicity
    /// is what makes the conditional maximum likelihood estimate a root-find rather than a search.
    public func mean(atLogOdds logOdds: Double) -> Double {
        let weights = probabilities(atLogOdds: logOdds)
        var total = 0.0
        for index in weights.indices {
            total += Double(lowerSupport + index) * weights[index]
        }
        return total
    }

    /// The probability of exactly `count` at odds ratio `exp(logOdds)`, or `0` outside the support.
    public func probability(of count: Int, atLogOdds logOdds: Double) -> Double {
        guard support.contains(count) else { return 0 }
        return probabilities(atLogOdds: logOdds)[count - lowerSupport]
    }

    /// `P(A >= count)` at odds ratio `exp(logOdds)`, increasing in `logOdds`.
    public func probabilityAtOrAbove(_ count: Int, atLogOdds logOdds: Double) -> Double {
        tail(atLogOdds: logOdds) { $0 >= count }
    }

    /// `P(A <= count)` at odds ratio `exp(logOdds)`, decreasing in `logOdds`.
    public func probabilityAtOrBelow(_ count: Int, atLogOdds logOdds: Double) -> Double {
        tail(atLogOdds: logOdds) { $0 <= count }
    }

    /// `P(A > count) + P(A = count) / 2`, the mid-p replacement for ``probabilityAtOrAbove(_:atLogOdds:)``.
    ///
    /// The exact tail counts the observed table in full, which is what makes the interval it builds
    /// wider than its nominal level rather than narrower. Mid-p attributes half of that table to
    /// each side. It is not exact and does not claim to be; its coverage is right on average rather
    /// than guaranteed, which for a series that draws dozens of these intervals is the trade most
    /// callers actually want.
    public func midProbabilityAtOrAbove(_ count: Int, atLogOdds logOdds: Double) -> Double {
        tail(atLogOdds: logOdds) { $0 > count } + probability(of: count, atLogOdds: logOdds) / 2
    }

    /// `P(A < count) + P(A = count) / 2`.
    public func midProbabilityAtOrBelow(_ count: Int, atLogOdds logOdds: Double) -> Double {
        tail(atLogOdds: logOdds) { $0 < count } + probability(of: count, atLogOdds: logOdds) / 2
    }

    private func tail(atLogOdds logOdds: Double, where predicate: (Int) -> Bool) -> Double {
        let weights = probabilities(atLogOdds: logOdds)
        var total = 0.0
        for index in weights.indices where predicate(lowerSupport + index) {
            total += weights[index]
        }
        return total
    }

    static func logChoose(_ total: Int, _ chosen: Int) -> Double {
        lgamma(Double(total) + 1) - lgamma(Double(chosen) + 1) - lgamma(Double(total - chosen) + 1)
    }
}
