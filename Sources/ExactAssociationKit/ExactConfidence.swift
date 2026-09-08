import Foundation

/// The level an exact interval is drawn at, expressed the way an exact method needs it.
///
/// An asymptotic interval is parameterised by a normal multiplier because it is symmetric on the
/// log scale and the multiplier is where the level enters. An exact interval has no such scale: it
/// is built by inverting two one-sided tests, and what enters is the tail probability each of them
/// is allowed. The two parameterisations are the same information and neither converts into the
/// other without assuming the very approximation this package is here to check, which is why this
/// type exists beside ``AssociationTransportKit/ConfidenceLevel`` rather than wrapping it.
public struct ExactConfidence: Sendable, Equatable {

    /// The total probability outside the interval, split evenly between the two tails.
    public let alpha: Double

    /// A short name for a report.
    public let label: String

    /// - Throws: ``ExactAssociationError/alphaOutOfRange(_:)``.
    public init(alpha: Double, label: String) throws {
        guard alpha > 0, alpha < 1 else {
            throw ExactAssociationError.alphaOutOfRange(alpha)
        }
        self.alpha = alpha
        self.label = label
    }

    private init(unchecked alpha: Double, label: String) {
        self.alpha = alpha
        self.label = label
    }

    /// The probability allowed in each tail.
    public var tail: Double { alpha / 2 }

    /// The conventional two-sided 95% interval.
    public static let ninetyFive = ExactConfidence(unchecked: 0.05, label: "95%")

    /// A two-sided 99% interval, for a caller who intends to make several of these claims.
    public static let ninetyNine = ExactConfidence(unchecked: 0.01, label: "99%")
}
