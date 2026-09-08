import AssociationTransportKit
import Foundation
import Testing
@testable import ExactAssociationKit

@Suite("Audits")
struct AuditTests {

    static let split = try! ObservedPanel(counts: [[4, 1], [1, 6]])
    static let corpus = try! ObservedPanel(counts: [[36, 36, 0], [12, 12, 0], [0, 0, 0]])
    static let sparse = try! ObservedPanel(counts: [[12, 0], [3, 9]])
    static let pinned = try! ObservedPanel(counts: [[5, 0], [0, 0]])

    @Test("a panel is read block by block from its own counts")
    func panel() throws {
        let audit = try ExactAssociation.audit(Self.split)
        #expect(audit.blockCount == 1)
        #expect(audit.readings.count == 1)
        #expect(audit.degenerateBlocks.isEmpty)
        #expect(audit.comparisons.isEmpty)
        #expect(audit.distinguishableCount == 0)
        #expect(audit.confidence == .ninetyFive)
        let reading = try #require(audit.reading(for: PanelCell(row: 0, column: 0)))
        #expect(reading.block.a == 4)
        #expect(audit.reading(for: PanelCell(row: 1, column: 1)) == nil)
    }

    @Test("blocks whose margins allow one table are listed, not thrown")
    func degenerate() throws {
        let audit = try ExactAssociation.audit(Self.corpus)
        #expect(audit.blockCount == 4)
        #expect(audit.readings.count == 1)
        #expect(audit.degenerateBlocks == [
            PanelCell(row: 0, column: 1), PanelCell(row: 1, column: 0), PanelCell(row: 1, column: 1)
        ])
        #expect(audit.distinguishableCount == 0)
        #expect(abs(audit.widestFactor - 7.8283) < 1e-3)
    }

    @Test("a panel with nothing to estimate reports no understatement rather than none measured")
    func nothingToEstimate() throws {
        let audit = try ExactAssociation.audit(Self.pinned)
        #expect(audit.readings.isEmpty)
        #expect(audit.degenerateBlocks.count == 1)
        #expect(audit.widestFactor == 1)
        #expect(audit.widestUnderstatement == 1)
    }

    @Test("the two methods reach opposite conclusions on a block with no empty cell")
    func disagreement() throws {
        let structure = try StructureMeasurement.measure(Self.split, policy: .structural)
        let audit = try ExactAssociation.audit(structure)
        #expect(audit.comparisons.count == 1)
        let comparison = try #require(audit.comparison(for: PanelCell(row: 0, column: 0)))
        #expect(comparison.asymptotic.coversIndependence == false)
        #expect(comparison.exact.coversIndependence)
        #expect(comparison.verdictAgrees == false)
        #expect(comparison.asymptoticOverstatesEvidence)
        #expect(comparison.correctionWasRequired == false)
        #expect(comparison.understatement > 1)
        #expect(abs(comparison.asymptoticOddsRatio - 24) < 1e-12)
        #expect(comparison.estimate.value != nil)
        #expect(audit.disagreementCount == 1)
        #expect(audit.inventedCount == 0)
        #expect(audit.comparison(for: PanelCell(row: 9, column: 9)) == nil)
    }

    @Test("a block the asymptotic side cannot read at all is left uncompared")
    func woolfUndefined() throws {
        let structure = try StructureMeasurement.measure(Self.sparse, policy: .structural)
        #expect(structure.undefinedBlocks.count == 1)
        let audit = try ExactAssociation.audit(structure)
        #expect(audit.readings.count == 1)
        #expect(audit.comparisons.isEmpty)
        #expect(audit.widestUnderstatement == 1)
    }

    @Test("a corrected count is compared, and the comparison says it was invented")
    func invented() throws {
        let structure = try StructureMeasurement.measure(Self.sparse, policy: .haldaneAnscombe)
        let audit = try ExactAssociation.audit(structure)
        #expect(audit.comparisons.count == 1)
        #expect(audit.inventedCount == 1)
        #expect(audit.comparisons[0].correctionWasRequired)
        #expect(audit.comparisons[0].exact.upper == .infinity)
        #expect(audit.comparisons[0].understatement == .infinity)
    }

    @Test("comparing two levels is refused rather than reported as a width ratio")
    func levelMismatch() throws {
        let structure = try StructureMeasurement.measure(
            Self.split, policy: .structural, confidence: .ninetyNine
        )
        #expect(throws: ExactAssociationError.confidenceLevelMismatch(exact: "95%", asymptotic: "99%")) {
            _ = try ExactAssociation.audit(structure)
        }
        let matched = try ExactAssociation.audit(structure, at: .ninetyNine)
        #expect(matched.comparisons.count == 1)
    }
}
