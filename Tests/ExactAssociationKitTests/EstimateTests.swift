import Testing
@testable import ExactAssociationKit

@Suite("The conditional estimate")
struct EstimateTests {

    @Test("an interior count has a finite maximum the sample odds ratio overshoots")
    func interior() throws {
        let estimate = try ConditionalOddsEstimate.of(ExactBlock(a: 4, b: 1, c: 1, d: 6))
        let value = try #require(estimate.value)
        #expect(abs(value - 15.99493) < 1e-4)
        #expect(value < 24)
        #expect(estimate.label == "15.9949")
    }

    @Test("a count at the top of its support has no interior maximum")
    func unbounded() throws {
        let estimate = try ConditionalOddsEstimate.of(ExactBlock(a: 12, b: 0, c: 3, d: 9))
        #expect(estimate == .unbounded)
        #expect(estimate.value == nil)
        #expect(estimate.label == "inf")
    }

    @Test("a count at the bottom of its support is maximised at zero")
    func zero() throws {
        let estimate = try ConditionalOddsEstimate.of(ExactBlock(a: 0, b: 12, c: 9, d: 3))
        #expect(estimate == .zero)
        #expect(estimate.value == nil)
        #expect(estimate.label == "0")
    }

    @Test("a table already at independence estimates exactly one")
    func independent() throws {
        let estimate = try ConditionalOddsEstimate.of(ExactBlock(a: 36, b: 36, c: 12, d: 12))
        let value = try #require(estimate.value)
        #expect(abs(value - 1) < 1e-9)
    }
}
