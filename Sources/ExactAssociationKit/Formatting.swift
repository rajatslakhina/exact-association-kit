import Foundation

/// Number formatting shared by this package's reports, its demo and its README figures.
///
/// It exists as a public type because an interval whose ends are `0` and `infinity` is the normal
/// case here rather than an edge one, and every caller that prints one needs the same answer for
/// what those look like.
public enum Formatting {

    /// A fixed-point rendering, which is what a ratio near `1` should be read at.
    public static func decimal(_ value: Double, places: Int = 4) -> String {
        String(format: "%.\(places)f", value)
    }

    /// A rendering that survives an unbounded end.
    public static func ratio(_ value: Double) -> String {
        guard value.isFinite else { return "inf" }
        if value != 0, abs(value) < 0.001 || abs(value) >= 100_000 {
            return String(format: "%.4e", value)
        }
        return decimal(value)
    }

    /// An interval, rendered so that a bound of `0` or `inf` reads as the answer it is.
    public static func interval(_ interval: ExactInterval) -> String {
        "[\(ratio(interval.lower)), \(ratio(interval.upper))]"
    }
}
