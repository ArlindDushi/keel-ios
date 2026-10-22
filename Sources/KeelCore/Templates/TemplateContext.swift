import Foundation

/// Values and flags available to templates.
///
/// - `{{NAME}}` is replaced with `variables["NAME"]`.
/// - `{{#if flag}}`, `{{else}}` and `{{/if}}` on their own lines keep or drop the lines between them.
/// - Conditions support `!flag`, `a || b` and `a && b` (no parentheses; `&&` binds tighter).
public struct TemplateContext: Sendable {
    public var variables: [String: String]
    public var flags: Set<String>

    public init(variables: [String: String] = [:], flags: Set<String> = []) {
        self.variables = variables
        self.flags = flags
    }

    public func evaluate(_ expression: String) throws -> Bool {
        let alternatives = expression.components(separatedBy: "||")
        return try alternatives.contains { alternative in
            try alternative.components(separatedBy: "&&").allSatisfy { term in
                var name = term.trimmingCharacters(in: .whitespaces)
                var negated = false
                while name.hasPrefix("!") {
                    negated.toggle()
                    name = String(name.dropFirst()).trimmingCharacters(in: .whitespaces)
                }
                guard !name.isEmpty, name.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else {
                    throw TemplateError.invalidCondition(expression)
                }
                return flags.contains(name) != negated
            }
        }
    }
}

public enum TemplateError: LocalizedError, Equatable {
    case invalidCondition(String)
    case unknownVariable(String)
    case unbalancedBlock(line: Int)
    case unclosedBlock
    case inlineBlock(line: Int)
    case inFile(String, underlying: String)

    public var errorDescription: String? {
        switch self {
        case let .invalidCondition(expression): "Invalid template condition “\(expression)”."
        case let .unknownVariable(name): "Unknown template variable {{\(name)}}."
        case let .unbalancedBlock(line): "Unexpected {{else}} or {{/if}} on line \(line)."
        case .unclosedBlock: "A {{#if}} block isn't closed."
        case let .inlineBlock(line): "Block tags must be on their own line (line \(line))."
        case let .inFile(path, underlying): "\(path): \(underlying)"
        }
    }
}
