import AssociationTransportKit
import ExactAssociationKit
import Foundation

/// The panels this demo reads. Each one is a real shape this ecosystem has quoted a coefficient off.
enum Fixtures {

    /// Twelve items, no empty cell, and the two methods reach opposite conclusions on it.
    static let split = [[4, 1], [1, 6]]

    /// Twenty items, eight of them agreeing on each label. The smallest panel this series works with.
    static let small = [[8, 2], [2, 8]]

    /// The same shape with ten times the items, which is the only thing that changes below.
    static let large = [[80, 20], [20, 80]]

    /// Seven items in two cells, where Fisher's own test and Fisher's own interval disagree.
    static let corner = [[2, 0], [0, 5]]

    /// A panel with a category nobody in one row ever chose.
    static let sparse = [[12, 0], [3, 9]]

    /// The joint table under the shared demo's own three-way verdict margins, built on 2026-09-08.
    ///
    /// Nine scenarios of `llm-ecosystem-demo` publish coefficients over this fixture.
    static let corpus = [[36, 36, 0], [12, 12, 0], [0, 0, 0]]
}

enum Scenarios {

    static func run() async throws -> String {
        var out: [String] = []
        out.append("ExactAssociationKit demo — exact conditional inference for a local odds ratio")
        out.append(String(repeating: "=", count: 74))
        out.append(try oneBlock())
        out.append(try sampleSize())
        out.append(try emptyCell())
        out.append(try appCorpus())
        out.append(try testAgainstInterval())
        out.append(try conservatism())
        out.append(try await ledger())
        return out.joined(separator: "\n")
    }

    /// The comparison the package exists for, on a block with nothing wrong with it.
    private static func oneBlock() throws -> String {
        var out = [Line.heading(1, "One block, three intervals")]
        let panel = try ObservedPanel(counts: Fixtures.split)
        let block = try ExactBlock(panel: panel, block: PanelCell(row: 0, column: 0))
        let reading = try ExactReading.of(block)
        let structure = try StructureMeasurement.measure(panel, policy: .structural)
        let woolf = structure.readings[0]
        out.append(Line.field("block", Line.block(block)))
        out.append(Line.field("empty cells", "\(block.hasEmptyCell)"))
        out.append(Line.field("tables the margins allow", "\(reading.supportSize)"))
        out.append(Line.field("sample odds ratio ad/bc", Formatting.ratio(block.sampleOddsRatio ?? 0)))
        out.append(Line.field("conditional MLE", reading.estimate.label))
        out.append(Line.field("Woolf 95%, raw counts", Line.interval(ExactInterval(woolf))))
        out.append(Line.field("mid-p 95%", Line.interval(reading.midP)))
        out.append(Line.field("exact 95%", Line.interval(reading.exact)))
        out.append(Line.field("Fisher two-sided p", Formatting.decimal(reading.fisherP, places: 6)))
        out.append(Line.field("mid-p two-sided p", Formatting.decimal(reading.midPValue, places: 6)))
        out.append("")
        out.append("  Nothing is wrong with this block. It has no empty cell, so no correction was")
        out.append("  applied and no count was invented. The asymptotic interval clears independence")
        out.append("  and the exact one does not, and the entire difference is that twelve items are")
        out.append("  not enough for a normal approximation on a log scale.")
        return out.joined(separator: "\n")
    }

    /// The same shape, ten times the items.
    private static func sampleSize() throws -> String {
        var out = [Line.heading(2, "The same shape, ten times the items")]
        for counts in [Fixtures.small, Fixtures.large] {
            let panel = try ObservedPanel(counts: counts)
            let audit = try ExactAssociation.audit(
                StructureMeasurement.measure(panel, policy: .structural)
            )
            guard let comparison = audit.comparisons.first else { continue }
            out.append(Line.field("items", "\(panel.itemCount)"))
            out.append(Line.field("  Woolf", Formatting.interval(comparison.asymptotic)))
            out.append(Line.field("  exact", Formatting.interval(comparison.exact)))
            out.append(Line.field("  exact / Woolf log width", Formatting.decimal(comparison.understatement)))
            out.append(Line.field("  verdicts agree", "\(comparison.verdictAgrees)"))
        }
        out.append("")
        out.append("  Woolf is an asymptotic method and this is what its asymptote looks like: the")
        out.append("  same table shape converges on the exact answer as the counts grow. Neither")
        out.append("  panel has an empty cell, so both sides read the raw counts and nothing here")
        out.append("  is a correction artefact.")
        return out.joined(separator: "\n")
    }

    /// A block the asymptotic side cannot read without inventing a count.
    private static func emptyCell() throws -> String {
        var out = [Line.heading(3, "An empty cell: repaired, or not needed")]
        let panel = try ObservedPanel(counts: Fixtures.sparse)
        let raw = try StructureMeasurement.measure(panel, policy: .structural)
        let corrected = try StructureMeasurement.measure(panel, policy: .haldaneAnscombe)
        let block = try ExactBlock(panel: panel, block: PanelCell(row: 0, column: 0))
        let reading = try ExactReading.of(block)
        out.append(Line.field("block", Line.block(block)))
        out.append(Line.field("Woolf, uncorrected", raw.readings.isEmpty ? "undefined" : "defined"))
        out.append(Line.field("Woolf blocks undefined", "\(raw.undefinedBlocks.count) of \(panel.blockCount)"))
        out.append(Line.field("Woolf, +0.5 everywhere", Formatting.interval(ExactInterval(corrected.readings[0]))))
        out.append(Line.field("Woolf odds ratio", Formatting.ratio(corrected.readings[0].oddsRatio)))
        out.append(Line.field("conditional MLE", reading.estimate.label))
        out.append(Line.field("exact 95%", Formatting.interval(reading.exact)))
        out.append(Line.field("exact needed a correction", "false"))
        out.append("")
        out.append("  The correction is not a convention this package declines to follow. It is a")
        out.append("  repair an asymptotic estimator needs and a conditional one does not: the exact")
        out.append("  interval is built from the distribution of the count, and zero is a count.")
        return out.joined(separator: "\n")
    }

    /// The fixture nine scenarios of the shared demo compute over.
    private static func appCorpus() throws -> String {
        var out = [Line.heading(4, "The corpus this ecosystem publishes coefficients over")]
        let panel = try ObservedPanel(counts: Fixtures.corpus)
        let audit = try ExactAssociation.audit(panel)
        out.append(Line.field("items", "\(panel.itemCount)"))
        out.append(Line.field("blocks", "\(audit.blockCount)"))
        out.append(Line.field("readable at all", "\(audit.readings.count)"))
        out.append(Line.field("margins allow one table", "\(audit.degenerateBlocks.count)"))
        for position in audit.degenerateBlocks {
            out.append(Line.field("  pinned block", position.label))
        }
        for reading in audit.readings {
            out.append(Line.field("  block \(reading.position?.label ?? "")", Formatting.interval(reading.exact)))
            out.append(Line.field("    conditional MLE", reading.estimate.label))
            out.append(Line.field("    Fisher two-sided p", Formatting.decimal(reading.fisherP, places: 6)))
        }
        out.append(Line.field("distinguishable", "\(audit.distinguishableCount) of \(audit.blockCount)"))
        out.append("")
        out.append("  Three of these four blocks do not have an odds ratio that is small, or large,")
        out.append("  or uncertain. Their margins allow exactly one table, so there is nothing to")
        out.append("  estimate. Every ratio previously quoted for them was created by the correction.")
        return out.joined(separator: "\n")
    }

    /// Fisher's test and Fisher's interval, disagreeing on the same table.
    private static func testAgainstInterval() throws -> String {
        var out = [Line.heading(5, "When the test and the interval disagree")]
        let panel = try ObservedPanel(counts: Fixtures.corner)
        let block = try ExactBlock(panel: panel, block: PanelCell(row: 0, column: 0))
        let reading = try ExactReading.of(block)
        out.append(Line.field("block", Line.block(block)))
        out.append(Line.field("Fisher two-sided p", Formatting.decimal(reading.fisherP, places: 6)))
        out.append(Line.field("rejects at 5%", "\(reading.fisherP < 0.05)"))
        out.append(Line.field("exact 95%", Line.interval(reading.exact)))
        out.append(Line.field("mid-p 95%", Line.interval(reading.midP)))
        out.append("")
        out.append("  Both numbers are exact and they say different things. The two-sided test spends")
        out.append("  its whole 5% on one comparison and adds up every table at least as improbable")
        out.append("  as this one; the interval spends 2.5% on each side separately. On a support")
        out.append("  this coarse the two budgets do not meet, and a p-value is not a shorthand for")
        out.append("  whether an interval covers 1.")
        return out.joined(separator: "\n")
    }

    /// What the exact method's guarantee costs.
    private static func conservatism() throws -> String {
        var out = [Line.heading(6, "What the guarantee costs")]
        for counts in [[[4, 1], [1, 4]], [[8, 2], [2, 8]], [[20, 5], [5, 20]]] {
            let panel = try ObservedPanel(counts: counts)
            let block = try ExactBlock(panel: panel, block: PanelCell(row: 0, column: 0))
            let reading = try ExactReading.of(block)
            out.append(Line.field("items", "\(panel.itemCount), \(reading.supportSize) tables allowed"))
            out.append(Line.field("  exact", Formatting.interval(reading.exact)))
            out.append(Line.field("  mid-p", Formatting.interval(reading.midP)))
            out.append(Line.field("  exact / mid-p log width", Formatting.decimal(reading.conservatism)))
        }
        out.append("")
        out.append("  The exact interval is wider than its nominal level because a discrete support")
        out.append("  cannot place a tail probability at 0.025. The overshoot shrinks as the support")
        out.append("  gets finer, which is the same limit the asymptotic method is taking.")
        return out.joined(separator: "\n")
    }

    /// The ledger, over both panels the series actually quotes numbers from.
    private static func ledger() async throws -> String {
        var out = [Line.heading(7, "Ledger")]
        let ledger = ExactLedger()
        for (key, counts) in [("small", Fixtures.small), ("large", Fixtures.large)] {
            let panel = try ObservedPanel(counts: counts)
            let structure = try StructureMeasurement.measure(panel, policy: .structural)
            let audit = try await ledger.audit(structure, as: key)
            out.append(
                Line.field(
                    key,
                    "\(audit.distinguishableCount)/\(audit.blockCount) distinguishable, "
                        + "\(audit.disagreementCount) disagreement(s)"
                )
            )
        }
        out.append(Line.field("keys", (await ledger.keys).joined(separator: ", ")))
        out.append(Line.field("disagreements", "\(await ledger.disagreementTotal)"))
        out.append(Line.field("widest understatement", Formatting.decimal(await ledger.widestUnderstatement)))
        return out.joined(separator: "\n")
    }
}
