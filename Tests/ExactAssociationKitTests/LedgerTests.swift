import AssociationTransportKit
import Testing
@testable import ExactAssociationKit

@Suite("The ledger")
struct LedgerTests {

    static let split = try! ObservedPanel(counts: [[4, 1], [1, 6]])
    static let corpus = try! ObservedPanel(counts: [[36, 36, 0], [12, 12, 0], [0, 0, 0]])

    @Test("an empty ledger reports no understatement rather than a measurement of none")
    func empty() async {
        let ledger = ExactLedger()
        #expect(await ledger.keys.isEmpty)
        #expect(await ledger.recorded.isEmpty)
        #expect(await ledger.disagreementTotal == 0)
        #expect(await ledger.degenerateTotal == 0)
        #expect(await ledger.widestUnderstatement == 1)
    }

    @Test("audits accumulate under their keys, in arrival order")
    func accumulate() async throws {
        let ledger = ExactLedger()
        let structure = try StructureMeasurement.measure(Self.split, policy: .structural)
        let first = try await ledger.audit(structure, as: "split")
        #expect(first.disagreementCount == 1)
        await ledger.record(try ExactAssociation.audit(Self.corpus), as: "corpus")
        #expect(await ledger.keys == ["split", "corpus"])
        #expect(await ledger.disagreementTotal == 1)
        #expect(await ledger.degenerateTotal == 3)
        #expect(await ledger.widestUnderstatement > 1)
        #expect(await ledger.recorded.count == 2)
    }

    @Test("recording a key twice replaces the audit and keeps its place")
    func overwrite() async throws {
        let ledger = ExactLedger()
        await ledger.record(try ExactAssociation.audit(Self.split), as: "one")
        await ledger.record(try ExactAssociation.audit(Self.corpus), as: "two")
        await ledger.record(try ExactAssociation.audit(Self.corpus), as: "one")
        #expect(await ledger.keys == ["one", "two"])
        #expect(await ledger.degenerateTotal == 6)
        let stored = try await ledger.audit(for: "one")
        #expect(stored.degenerateBlocks.count == 3)
    }

    @Test("a key that was never recorded is refused")
    func unknown() async {
        let ledger = ExactLedger()
        await #expect(throws: ExactAssociationError.unknownAuditKey("missing")) {
            _ = try await ledger.audit(for: "missing")
        }
    }
}
