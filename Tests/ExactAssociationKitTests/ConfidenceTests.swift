import Testing
@testable import ExactAssociationKit

@Suite("Confidence levels")
struct ConfidenceTests {

    @Test("the level is stored as the probability outside the interval")
    func levels() {
        #expect(ExactConfidence.ninetyFive.alpha == 0.05)
        #expect(ExactConfidence.ninetyFive.tail == 0.025)
        #expect(ExactConfidence.ninetyFive.label == "95%")
        #expect(ExactConfidence.ninetyNine.alpha == 0.01)
        #expect(ExactConfidence.ninetyNine.label == "99%")
    }

    @Test("a caller's own level is accepted, and an impossible one is refused")
    func custom() throws {
        let level = try ExactConfidence(alpha: 0.2, label: "80%")
        #expect(level.tail == 0.1)
        #expect(throws: ExactAssociationError.alphaOutOfRange(0)) {
            _ = try ExactConfidence(alpha: 0, label: "100%")
        }
        #expect(throws: ExactAssociationError.alphaOutOfRange(1)) {
            _ = try ExactConfidence(alpha: 1, label: "0%")
        }
    }
}
