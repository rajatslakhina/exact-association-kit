import Foundation
import Testing
@testable import ExactAssociationKit

@Suite("Readings")
struct ReadingTests {

    @Test("the twelve-item block, to the last digit")
    func split() throws {
        let reading = try ExactReading.of(ExactBlock(a: 4, b: 1, c: 1, d: 6))
        #expect(reading.supportSize == 6)
        #expect(reading.sampleOddsRatio == 24)
        #expect(abs(reading.exact.lower - 0.747361782958) < 1e-9)
        #expect(abs(reading.exact.upper - 1370.981089068) < 1e-6)
        #expect(reading.exact.coversIndependence)
        #expect(reading.isDistinguishable == false)
        #expect(abs(reading.fisherP - 0.0719696969697) < 1e-10)
        #expect(reading.midPValue < reading.fisherP)
        #expect(reading.position == nil)
        #expect(reading.confidence == .ninetyFive)
    }

    @Test("a count at the top of its support bounds the odds ratio from below only")
    func upperBoundary() throws {
        let reading = try ExactReading.of(ExactBlock(a: 2, b: 0, c: 0, d: 5))
        #expect(reading.exact.upper == .infinity)
        #expect(abs(reading.exact.lower - 0.650552533012) < 1e-9)
        #expect(reading.exact.coversIndependence)
        #expect(abs(reading.fisherP - 0.047619047619) < 1e-10)
        #expect(reading.fisherP < 0.05)
        #expect(reading.midP.lower > 1)
        #expect(reading.midP.coversIndependence == false)
    }

    @Test("a count at the bottom of its support bounds it from above only")
    func lowerBoundary() throws {
        let reading = try ExactReading.of(ExactBlock(a: 0, b: 2, c: 5, d: 0))
        #expect(reading.exact.lower == 0)
        #expect(abs(reading.exact.upper - 1.537154878746) < 1e-9)
        #expect(reading.midP.lower == 0)
        #expect(reading.estimate == .zero)
    }

    @Test("the mid-p interval sits inside the exact one, and the gap is the guarantee")
    func conservatism() throws {
        for counts in [(4, 1, 1, 4), (8, 2, 2, 8), (20, 5, 5, 20)] {
            let reading = try ExactReading.of(
                ExactBlock(a: counts.0, b: counts.1, c: counts.2, d: counts.3)
            )
            #expect(reading.midP.lower >= reading.exact.lower)
            #expect(reading.midP.upper <= reading.exact.upper)
            #expect(reading.conservatism > 1)
            #expect(reading.midPValue < reading.fisherP)
        }
    }

    @Test("a symmetric table's mirror image is counted once, not by rounding")
    func ties() throws {
        let reading = try ExactReading.of(ExactBlock(a: 8, b: 2, c: 2, d: 8))
        let mirrored = try ExactReading.of(ExactBlock(a: 2, b: 8, c: 8, d: 2))
        #expect(abs(reading.fisherP - mirrored.fisherP) < 1e-15)
        #expect(abs(reading.fisherP - 4252.0 / 184_756.0) < 1e-15)
        #expect(reading.fisherP <= 1)
    }

    @Test("a table at independence cannot be told from it at any level")
    func independent() throws {
        let reading = try ExactReading.of(ExactBlock(a: 36, b: 36, c: 12, d: 12), at: .ninetyNine)
        #expect(reading.fisherP == 1)
        #expect(reading.midPValue < 1)
        #expect(reading.exact.coversIndependence)
        #expect(reading.confidence == .ninetyNine)
    }
}
