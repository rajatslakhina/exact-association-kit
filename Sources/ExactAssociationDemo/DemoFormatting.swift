import ExactAssociationKit
import Foundation

enum Line {

    static func heading(_ number: Int, _ title: String) -> String {
        "\n\(number). \(title)\n" + String(repeating: "-", count: 74)
    }

    static func field(_ name: String, _ value: String) -> String {
        let padded = name.padding(toLength: max(name.count, 26), withPad: " ", startingAt: 0)
        return "  \(padded)\(value)"
    }

    static func block(_ block: ExactBlock) -> String {
        "[\(block.a), \(block.b); \(block.c), \(block.d)]"
    }

    static func verdict(_ covers: Bool) -> String {
        covers ? "covers 1 (not distinguishable)" : "clears 1 (distinguishable)"
    }

    static func interval(_ value: ExactInterval) -> String {
        "\(Formatting.interval(value))  \(verdict(value.coversIndependence))"
    }
}
