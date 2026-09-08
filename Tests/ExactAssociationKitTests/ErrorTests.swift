import Testing
@testable import ExactAssociationKit

@Suite("Refusals")
struct ErrorTests {

    @Test("every refusal says what it refused and why")
    func descriptions() {
        #expect(
            ExactAssociationError.negativeCount(position: "c", count: -2).description
                == "count at c is -2; a block is made of whole non-negative items"
        )
        #expect(
            ExactAssociationError
                .degenerateSupport(rowTotal: 12, otherRowTotal: 0, columnTotal: 12).description
                == "margins 12/0 by 12 pin the block to one table; no method can read an odds ratio off it"
        )
        #expect(
            ExactAssociationError.alphaOutOfRange(1.5).description
                == "confidence alpha 1.5 is not strictly between 0 and 1"
        )
        #expect(
            ExactAssociationError.blockOutOfRange(row: 1, column: 0, categoryCount: 2).description
                == "block (1, 0) is not a two-by-two block of a 2-category panel"
        )
        #expect(
            ExactAssociationError.confidenceLevelMismatch(exact: "95%", asymptotic: "99%").description
                == "exact reading at 95% cannot be compared with an asymptotic one at 99%"
        )
        #expect(
            ExactAssociationError.unknownAuditKey("missing").description == "no audit recorded under missing"
        )
    }
}
