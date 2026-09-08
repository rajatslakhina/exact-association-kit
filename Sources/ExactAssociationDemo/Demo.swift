import ExactAssociationKit
import Foundation

@main
enum ExactAssociationDemo {

    static func main() async {
        do {
            print(try await Scenarios.run())
        } catch {
            print("demo failed: \(error)")
            exit(1)
        }
    }
}
