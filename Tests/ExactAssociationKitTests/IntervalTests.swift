import AssociationTransportKit
import Foundation
import Testing
@testable import ExactAssociationKit

@Suite("Intervals and their rendering")
struct IntervalTests {

    @Test("a bounded interval reports a finite width and a finite factor")
    func bounded() {
        let interval = ExactInterval(lower: 2, upper: 8, method: .exactConditional)
        #expect(interval.isBounded)
        #expect(abs(interval.logWidth - log(4.0)) < 1e-12)
        #expect(abs(interval.factor - 4) < 1e-12)
        #expect(interval.coversIndependence == false)
    }

    @Test("an interval with an unbounded end says so rather than returning a number")
    func unbounded() {
        let above = ExactInterval(lower: 0.5, upper: .infinity, method: .midP)
        #expect(above.isBounded == false)
        #expect(above.logWidth == .infinity)
        #expect(above.factor == .infinity)
        #expect(above.coversIndependence)
        let below = ExactInterval(lower: 0, upper: 0.5, method: .exactConditional)
        #expect(below.isBounded == false)
        #expect(below.factor == .infinity)
        #expect(below.coversIndependence == false)
    }

    @Test("a Woolf reading converts into the same type so the two can be compared")
    func fromWoolf() throws {
        let panel = try ObservedPanel(counts: [[4, 1], [1, 6]])
        let structure = try StructureMeasurement.measure(panel, policy: .structural)
        let interval = ExactInterval(structure.readings[0])
        #expect(interval.method == .woolf)
        #expect(abs(interval.lower - 1.14015702556745) < 1e-12)
        #expect(abs(interval.upper - 505.193571660298) < 1e-10)
    }

    @Test("every method names itself")
    func labels() {
        #expect(IntervalMethod.exactConditional.label == "exact")
        #expect(IntervalMethod.midP.label == "mid-p")
        #expect(IntervalMethod.woolf.label == "Woolf")
    }

    @Test("formatting survives both unbounded ends and both extremes of scale")
    func formatting() {
        #expect(Formatting.decimal(1.5) == "1.5000")
        #expect(Formatting.decimal(1.5, places: 2) == "1.50")
        #expect(Formatting.ratio(.infinity) == "inf")
        #expect(Formatting.ratio(0) == "0.0000")
        #expect(Formatting.ratio(1.5) == "1.5000")
        #expect(Formatting.ratio(0.0001) == "1.0000e-04")
        #expect(Formatting.ratio(123_456) == "1.2346e+05")
        #expect(
            Formatting.interval(ExactInterval(lower: 0, upper: .infinity, method: .exactConditional))
                == "[0.0000, inf]"
        )
    }
}
