import Foundation
import Testing
@testable import ExactAssociationKit

@Suite("The conditional distribution")
struct DistributionTests {

    static let split = try! NoncentralHypergeometric(rowTotal: 5, otherRowTotal: 7, columnTotal: 5)

    @Test("the support is what the margins allow, and its size bounds every p-value")
    func support() {
        #expect(Self.split.support == 0...5)
        #expect(Self.split.supportSize == 6)
        #expect(Self.split.rowTotal == 5)
        #expect(Self.split.otherRowTotal == 7)
        #expect(Self.split.columnTotal == 5)
        let shifted = try! NoncentralHypergeometric(rowTotal: 12, otherRowTotal: 12, columnTotal: 15)
        #expect(shifted.support == 3...12)
    }

    @Test("margins that allow one table are refused rather than reported as certainty")
    func degenerate() {
        #expect(throws: ExactAssociationError.degenerateSupport(rowTotal: 12, otherRowTotal: 0, columnTotal: 12)) {
            _ = try NoncentralHypergeometric(rowTotal: 12, otherRowTotal: 0, columnTotal: 12)
        }
        #expect(throws: ExactAssociationError.degenerateSupport(rowTotal: 0, otherRowTotal: 5, columnTotal: 0)) {
            _ = try NoncentralHypergeometric(rowTotal: 0, otherRowTotal: 5, columnTotal: 0)
        }
    }

    @Test("at an odds ratio of one it is the central hypergeometric distribution")
    func central() {
        let weights = Self.split.probabilities(atLogOdds: 0)
        #expect(abs(weights.reduce(0, +) - 1) < 1e-12)
        let total = exp(NoncentralHypergeometric.logChoose(12, 5))
        for value in 0...5 {
            let expected = exp(
                NoncentralHypergeometric.logChoose(5, value) + NoncentralHypergeometric.logChoose(7, 5 - value)
            ) / total
            #expect(abs(weights[value] - expected) < 1e-12)
        }
    }

    @Test("the mean increases with the odds ratio and stays inside the support")
    func mean() {
        let distribution = Self.split
        var previous = -Double.infinity
        for logOdds in stride(from: -20.0, through: 20.0, by: 0.5) {
            let value = distribution.mean(atLogOdds: logOdds)
            #expect(value > previous)
            #expect(value >= Double(distribution.lowerSupport))
            #expect(value <= Double(distribution.upperSupport))
            previous = value
        }
        #expect(abs(distribution.mean(atLogOdds: -700) - 0) < 1e-9)
        #expect(abs(distribution.mean(atLogOdds: 700) - 5) < 1e-9)
    }

    @Test("the two tails overlap in exactly the observed table")
    func tails() {
        let distribution = Self.split
        for logOdds in [-2.0, 0.0, 1.5] {
            let above = distribution.probabilityAtOrAbove(3, atLogOdds: logOdds)
            let below = distribution.probabilityAtOrBelow(3, atLogOdds: logOdds)
            let point = distribution.probability(of: 3, atLogOdds: logOdds)
            #expect(abs(above + below - point - 1) < 1e-12)
            #expect(abs(distribution.midProbabilityAtOrAbove(3, atLogOdds: logOdds) - (above - point / 2)) < 1e-12)
            #expect(abs(distribution.midProbabilityAtOrBelow(3, atLogOdds: logOdds) - (below - point / 2)) < 1e-12)
        }
    }

    @Test("a count the margins do not allow has probability zero")
    func outsideSupport() {
        #expect(Self.split.probability(of: 6, atLogOdds: 0) == 0)
        #expect(Self.split.probability(of: -1, atLogOdds: 0) == 0)
    }
}
