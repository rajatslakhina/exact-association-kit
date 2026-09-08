import AssociationTransportKit
import Foundation

/// One block's exact interval set beside the asymptotic one this series has been quoting.
///
/// The two are not competing estimates of the same number. They are two intervals for the same
/// parameter built on different premises, and the comparison is only meaningful when both are drawn
/// at the same level and around the same block — which is why ``ExactAssociation`` refuses to build
/// one otherwise rather than reporting a ratio nobody can interpret.
///
/// Note what the asymptotic side had to do first. Woolf's standard error is a sum of reciprocals,
/// so a block with an empty cell has no interval at all until something is added to every count.
/// The exact side needs no such repair, which makes ``correctionWasRequired`` the honest name for
/// what separates them: on those blocks the comparison is not exact-versus-asymptotic but
/// exact-versus-invented.
public struct WoolfComparison: Sendable, Equatable {

    /// Which block.
    public let position: PanelCell

    /// The exact conditional interval, from the uncorrected counts.
    public let exact: ExactInterval

    /// The Woolf interval, from whatever counts the measurement was taken on.
    public let asymptotic: ExactInterval

    /// The conditional maximum likelihood estimate.
    public let estimate: ConditionalOddsEstimate

    /// The odds ratio the asymptotic interval is centred on.
    public let asymptoticOddsRatio: Double

    /// `true` when the block contained an empty cell, so the asymptotic side needed a correction.
    public let correctionWasRequired: Bool

    /// How much wider the exact interval is, on the log scale.
    ///
    /// Greater than `1` means the asymptotic interval understated the uncertainty by that factor.
    /// It is worth being precise about how often that happens, because "asymptotic methods are
    /// approximate" leaves the direction open and the direction is the whole point: swept over
    /// every two-by-two table of at most forty items whose count sits strictly inside its support,
    /// this ratio was **never** below `1`. Woolf is not sometimes optimistic on small tables. In
    /// the range this series works in, it is optimistic on all of them.
    public var understatement: Double { exact.logWidth / asymptotic.logWidth }

    /// `true` when both intervals reach the same conclusion about independence.
    public var verdictAgrees: Bool { exact.coversIndependence == asymptotic.coversIndependence }

    /// `true` when the asymptotic interval clears independence and the exact one does not.
    public var asymptoticOverstatesEvidence: Bool {
        !asymptotic.coversIndependence && exact.coversIndependence
    }
}
