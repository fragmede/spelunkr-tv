import Foundation

enum ArchiveURL {
    static let componentCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))

    static func component(_ value: String) -> String? {
        value.addingPercentEncoding(withAllowedCharacters: componentCharacters)
    }

    static func media(identifier: String, file: String?) -> URL? {
        guard let file, !file.isEmpty, let identifier = component(identifier), let file = component(file) else { return nil }
        return URL(string: "https://archive.org/download/\(identifier)/\(file)")
    }

    static func page(identifier: String) -> URL? {
        component(identifier).flatMap { URL(string: "https://archive.org/details/\($0)") }
    }

    static func thumbnail(identifier: String) -> URL? {
        component(identifier).flatMap { URL(string: "https://archive.org/services/img/\($0)") }
    }
}
