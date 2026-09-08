import AssociationTransportKit
import Foundation

/// Keeps the audits a caller has taken, so a run can be asked what it found overall.
///
/// The actor exists for the same reason the rest of this series has one: an audit is cheap to
/// compute and expensive to reconcile, and a caller that draws forty intervals wants one place to
/// ask how many of them survived rather than forty answers to carry around.
public actor ExactLedger {

    private var audits: [String: ExactAudit] = [:]
    private var order: [String] = []

    public init() {}

    /// Audits `structure` against its own Woolf readings and records the result under `key`.
    ///
    /// - Throws: ``ExactAssociationError/confidenceLevelMismatch(exact:asymptotic:)``.
    @discardableResult
    public func audit(
        _ structure: MeasuredStructure,
        at confidence: ExactConfidence = .ninetyFive,
        as key: String
    ) throws -> ExactAudit {
        let result = try ExactAssociation.audit(structure, at: confidence)
        record(result, as: key)
        return result
    }

    /// Records an audit taken elsewhere.
    public func record(_ audit: ExactAudit, as key: String) {
        if audits[key] == nil {
            order.append(key)
        }
        audits[key] = audit
    }

    /// - Throws: ``ExactAssociationError/unknownAuditKey(_:)``.
    public func audit(for key: String) throws -> ExactAudit {
        guard let audit = audits[key] else {
            throw ExactAssociationError.unknownAuditKey(key)
        }
        return audit
    }

    /// Every key recorded, in the order it first arrived.
    public var keys: [String] { order }

    /// Every audit recorded, in the order its key first arrived.
    public var recorded: [ExactAudit] { order.compactMap { audits[$0] } }

    /// How many blocks across every audit reach different conclusions under the two methods.
    public var disagreementTotal: Int {
        recorded.reduce(0) { $0 + $1.disagreementCount }
    }

    /// How many blocks across every audit had margins that left nothing to estimate.
    public var degenerateTotal: Int {
        recorded.reduce(0) { $0 + $1.degenerateBlocks.count }
    }

    /// The largest understatement factor any audit measured.
    public var widestUnderstatement: Double {
        recorded.map(\.widestUnderstatement).max() ?? 1
    }
}
