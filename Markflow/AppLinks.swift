import Foundation

enum AppLinks {
    static let website = "https://santiagoalonso.com"
    static let support = "https://github.com/madebysan/markflow/blob/main/docs/support.md"
    static let privacy = "https://github.com/madebysan/markflow/blob/main/docs/privacy-policy.md"

    static func url(_ string: String) -> URL? {
        URL(string: string)
    }
}
