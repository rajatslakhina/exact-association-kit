import AssociationTransportKit
import Foundation

/// Every block of a panel, read exactly.
///
/// Blocks whose margins leave nothing to estimate are listed rather than thrown, because a panel
/// that contains several of them is the interesting case rather than the broken one: an empty
/// category pins whole blocks to a single table, and a method that repairs its way past that is
/// reporting an odds ratio the panel does not contain.
public struct ExactAudit: Sendable, Equatable {

    /// The panel that was read.
    public let panel: ObservedPanel

    /// The level every interval was drawn at.
    public let confidence: ExactConfidence

    /// One reading per block the margins leave something to estimate.
    public let readings: [ExactReading]

    /// Blocks whose margins allow exactly one table.
    public let degenerateBlocks: [PanelCell]

    /// One comparison per block that both this package and an asymptotic measurement could read.
    public let comparisons: [WoolfComparison]

    /// How many blocks the panel has.
    public var blockCount: Int { panel.blockCount }

    /// How many of them the panel can distinguish from independence.
    public var distinguishableCount: Int { readings.filter(\.isDistinguishable).count }

    /// How many comparisons reach different conclusions.
    public var disagreementCount: Int { comparisons.filter { !$0.verdictAgrees }.count }

    /// How many comparisons had an asymptotic side that only existed because of a correction.
    public var inventedCount: Int { comparisons.filter(\.correctionWasRequired).count }

    /// The largest factor by which the asymptotic side understated an interval's width.
    ///
    /// `1` when nothing was compared, which reads as "no understatement measured" rather than as a
    /// measurement of none.
    public var widestUnderstatement: Double {
        comparisons.map(\.understatement).max() ?? 1
    }

    /// The widest exact interval, as a multiplicative factor.
    public var widestFactor: Double {
        readings.map(\.exact.factor).max() ?? 1
    }

    /// The reading for `block`, when there is one.
    public func reading(for block: PanelCell) -> ExactReading? {
        readings.first { $0.position == block }
    }

    /// The comparison for `block`, when there is one.
    public func comparison(for block: PanelCell) -> WoolfComparison? {
        comparisons.first { $0.position == block }
    }
}

/// Reading a whole panel exactly, with or without an asymptotic measurement to check.
public enum ExactAssociation {

    /// Reads every block of `panel` from its uncorrected counts.
    ///
    /// - Throws: nothing from a degenerate block, which is listed instead; only
    ///   ``ExactAssociationError/blockOutOfRange(row:column:categoryCount:)`` can escape, and only
    ///   from a panel this package built the block list for itself, which is to say never.
    public static func audit(
        _ panel: ObservedPanel,
        at confidence: ExactConfidence = .ninetyFive
    ) throws -> ExactAudit {
        var readings: [ExactReading] = []
        var degenerate: [PanelCell] = []
        for position in panel.blocks {
            let block = try ExactBlock(panel: panel, block: position)
            do {
                readings.append(try ExactReading.of(block, at: confidence, position: position))
            } catch ExactAssociationError.degenerateSupport {
                degenerate.append(position)
            }
        }
        return ExactAudit(
            panel: panel, confidence: confidence, readings: readings,
            degenerateBlocks: degenerate, comparisons: []
        )
    }

    /// Reads every block of `structure`'s panel exactly and pairs each one with its Woolf interval.
    ///
    /// - Throws: ``ExactAssociationError/confidenceLevelMismatch(exact:asymptotic:)`` when the two
    ///   sides were drawn at different levels.
    public static func audit(
        _ structure: MeasuredStructure,
        at confidence: ExactConfidence = .ninetyFive
    ) throws -> ExactAudit {
        guard confidence.label == structure.confidence.label else {
            throw ExactAssociationError.confidenceLevelMismatch(
                exact: confidence.label, asymptotic: structure.confidence.label
            )
        }
        let base = try audit(structure.panel, at: confidence)
        var comparisons: [WoolfComparison] = []
        for position in base.panel.blocks {
            guard
                let reading = base.reading(for: position),
                let woolf = structure.reading(for: position)
            else { continue }
            comparisons.append(
                WoolfComparison(
                    position: position,
                    exact: reading.exact,
                    asymptotic: ExactInterval(woolf),
                    estimate: reading.estimate,
                    asymptoticOddsRatio: woolf.oddsRatio,
                    correctionWasRequired: reading.block.hasEmptyCell
                )
            )
        }
        return ExactAudit(
            panel: base.panel, confidence: confidence, readings: base.readings,
            degenerateBlocks: base.degenerateBlocks, comparisons: comparisons
        )
    }
}
