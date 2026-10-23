import Foundation

public struct TemplateRenderer: Sendable {
    public let context: TemplateContext

    public init(context: TemplateContext) {
        self.context = context
    }

    private struct Block {
        let parentActive: Bool
        var conditionMet: Bool
        var inElse = false

        var isActive: Bool { parentActive && (inElse ? !conditionMet : conditionMet) }
    }

    public func render(_ template: String) throws -> String {
        var output: [Substring] = []
        var blocks: [Block] = []
        var isActive: Bool { blocks.last?.isActive ?? true }

        let lines = template.split(separator: "\n", omittingEmptySubsequences: false)
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            if let match = line.wholeMatch(of: Self.ifPattern) {
                let met = isActive ? try context.evaluate(String(match.1)) : false
                blocks.append(Block(parentActive: isActive, conditionMet: met))
            } else if line.wholeMatch(of: Self.elsePattern) != nil {
                guard var block = blocks.popLast(), !block.inElse else { throw TemplateError.unbalancedBlock(line: lineNumber) }
                block.inElse = true
                blocks.append(block)
            } else if line.wholeMatch(of: Self.endPattern) != nil {
                guard blocks.popLast() != nil else { throw TemplateError.unbalancedBlock(line: lineNumber) }
            } else if line.contains("{{#if") || line.contains("{{else}}") || line.contains("{{/if}}") {
                throw TemplateError.inlineBlock(line: lineNumber)
            } else if isActive {
                output.append(Substring(try substitute(line)))
            }
        }
        guard blocks.isEmpty else { throw TemplateError.unclosedBlock }
        return output.joined(separator: "\n")
    }
}

private extension TemplateRenderer {
    static var variablePattern: Regex<(Substring, Substring)> { /\{\{([A-Z][A-Z0-9_]*)\}\}/ }
    static var ifPattern: Regex<(Substring, Substring)> { /^\s*\{\{#if\s+(.+?)\s*\}\}\s*$/ }
    static var elsePattern: Regex<Substring> { /^\s*\{\{else\}\}\s*$/ }
    static var endPattern: Regex<Substring> { /^\s*\{\{\/if\}\}\s*$/ }

    /// Replaces `{{NAME}}` placeholders. A multi-line value on a line of its own is
    /// indented to the placeholder's indentation.
    func substitute(_ line: Substring) throws -> String {
        var indentation = ""
        if let match = line.wholeMatch(of: /(\s*)\{\{[A-Z][A-Z0-9_]*\}\}\s*/) {
            indentation = String(match.1)
        }
        var result = ""
        var rest = line[...]
        while let match = rest.firstMatch(of: Self.variablePattern) {
            let name = String(match.1)
            guard let value = context.variables[name] else { throw TemplateError.unknownVariable(name) }
            result += rest[..<match.range.lowerBound]
            result += indentation.isEmpty ? value : value.replacingOccurrences(of: "\n", with: "\n" + indentation)
            rest = rest[match.range.upperBound...]
        }
        return result + rest
    }
}
