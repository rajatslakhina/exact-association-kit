import Foundation

/// Bisection on the log odds scale.
///
/// Every quantity this package solves for — a conditional mean, a one-sided tail probability — is
/// monotone in the log odds ratio, and none of them has a closed form. Bisection is chosen over
/// anything faster because the functions are sums over a discrete support and are therefore
/// piecewise flat in places: a Newton step needs a derivative that is legitimately zero over
/// stretches of the line, and a secant step walks off the end of the bracket when it is.
enum RootSolver {

    /// The widest log odds ratio worth searching: `exp` of anything larger is not a `Double`.
    static let bound = 700.0

    /// Returns the log odds ratio at which `evaluate` crosses `target`.
    ///
    /// `evaluate` must be non-decreasing. The iteration count is fixed rather than
    /// tolerance-driven: the bracket is 1400 wide and halves every pass, so 120 of them takes it
    /// below the spacing of a `Double` anywhere in that range, and a fixed count cannot fail to
    /// terminate on a function with a flat step exactly at `target`.
    static func crossing(of target: Double, _ evaluate: (Double) -> Double) -> Double {
        var low = -bound
        var high = bound
        for _ in 0..<120 {
            let middle = (low + high) / 2
            if evaluate(middle) < target {
                low = middle
            } else {
                high = middle
            }
        }
        return (low + high) / 2
    }
}
