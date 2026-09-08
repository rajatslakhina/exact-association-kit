import AssociationTransportKit
import Foundation

/// Everything the conditional likelihood has to say about one block.
///
/// The two intervals are the same inversion under two accounting rules for the observed table, and
/// the gap between them is the price of the exact method's guarantee. Both p-values are computed at
/// an odds ratio of exactly `1`, which is the only place a test of independence lives.
public struct ExactReading: Sendable, Equatable {

    /// The counts, uncorrected.
    public let block: ExactBlock

    /// Where the block sat, when it was read off a panel.
    public let position: PanelCell?

    /// The level both intervals were drawn at.
    public let confidence: ExactConfidence

    /// The conditional maximum likelihood estimate.
    public let estimate: ConditionalOddsEstimate

    /// The exact conditional interval. Coverage at least the nominal level, and usually more.
    public let exact: ExactInterval

    /// The mid-p interval. Coverage right on average, and narrower.
    public let midP: ExactInterval

    /// Fisher's exact two-sided p-value against independence.
    public let fisherP: Double

    /// Its mid-p counterpart, which is the same sum with the observed table counted half.
    public let midPValue: Double

    /// How many tables these margins allow.
    public let supportSize: Int

    /// The sample odds ratio, or `nil` when a zero count leaves it undefined.
    public var sampleOddsRatio: Double? { block.sampleOddsRatio }

    /// `true` when the exact interval clears independence.
    public var isDistinguishable: Bool { !exact.coversIndependence }

    /// How much wider the exact interval is than the mid-p one, on the log scale.
    ///
    /// This is the cost of the guarantee, and it is entirely a function of how coarse the support
    /// is: a block whose margins allow four tables cannot place a tail probability anywhere near
    /// `0.025`, so the exact interval overshoots to the next attainable one.
    public var conservatism: Double { exact.logWidth / midP.logWidth }

    /// Reads `block`.
    ///
    /// - Throws: ``ExactAssociationError/degenerateSupport(rowTotal:otherRowTotal:columnTotal:)``.
    public static func of(
        _ block: ExactBlock,
        at confidence: ExactConfidence = .ninetyFive,
        position: PanelCell? = nil
    ) throws -> ExactReading {
        let distribution = try block.conditionalDistribution()
        let count = block.a
        let tail = confidence.tail
        let exact = ExactInterval(
            lower: lowerBound(distribution, count, tail) { distribution.probabilityAtOrAbove(count, atLogOdds: $0) },
            upper: upperBound(distribution, count, tail) { distribution.probabilityAtOrBelow(count, atLogOdds: $0) },
            method: .exactConditional
        )
        let midP = ExactInterval(
            lower: lowerBound(distribution, count, tail) {
                distribution.midProbabilityAtOrAbove(count, atLogOdds: $0)
            },
            upper: upperBound(distribution, count, tail) {
                distribution.midProbabilityAtOrBelow(count, atLogOdds: $0)
            },
            method: .midP
        )
        let values = pValues(distribution, count)
        return ExactReading(
            block: block,
            position: position,
            confidence: confidence,
            estimate: try ConditionalOddsEstimate.of(block),
            exact: exact,
            midP: midP,
            fisherP: values.fisher,
            midPValue: values.mid,
            supportSize: distribution.supportSize
        )
    }

    /// Zero when the count sits at the bottom of its support: nothing bounds the odds ratio below.
    private static func lowerBound(
        _ distribution: NoncentralHypergeometric,
        _ count: Int,
        _ tail: Double,
        _ evaluate: @escaping (Double) -> Double
    ) -> Double {
        guard count > distribution.lowerSupport else { return 0 }
        return Foundation.exp(RootSolver.crossing(of: tail, evaluate))
    }

    /// Infinite when the count sits at the top of its support.
    private static func upperBound(
        _ distribution: NoncentralHypergeometric,
        _ count: Int,
        _ tail: Double,
        _ evaluate: @escaping (Double) -> Double
    ) -> Double {
        guard count < distribution.upperSupport else { return .infinity }
        return Foundation.exp(RootSolver.crossing(of: -tail) { -evaluate($0) })
    }

    /// Both two-sided p-values, by the minimum-likelihood rule.
    ///
    /// Every table at least as improbable as the observed one counts against independence. The
    /// comparison is made with a relative tolerance because a table and its mirror image are equally
    /// probable by construction and their computed probabilities differ in the last bit or two;
    /// without it a symmetric block reports a p-value that depends on rounding.
    private static func pValues(
        _ distribution: NoncentralHypergeometric,
        _ count: Int
    ) -> (fisher: Double, mid: Double) {
        let weights = distribution.probabilities(atLogOdds: 0)
        let observed = weights[count - distribution.lowerSupport]
        let tolerance = observed * 1e-9
        var below = 0.0
        var equal = 0.0
        for weight in weights {
            if weight < observed - tolerance {
                below += weight
            } else if weight <= observed + tolerance {
                equal += weight
            }
        }
        return (fisher: Swift.min(1, below + equal), mid: Swift.min(1, below + equal / 2))
    }
}
