import Testing
@testable import KeelCore

struct TemplateRendererTests {
    private func render(_ template: String, variables: [String: String] = [:], flags: Set<String> = []) throws -> String {
        try TemplateRenderer(context: TemplateContext(variables: variables, flags: flags)).render(template)
    }

    @Test func replacesVariables() throws {
        #expect(try render("Hello {{NAME}}!", variables: ["NAME": "World"]) == "Hello World!")
    }

    @Test func unknownVariableThrows() {
        #expect(throws: TemplateError.unknownVariable("MISSING")) {
            try render("{{MISSING}}")
        }
    }

    @Test func keepsOrDropsBlocks() throws {
        let template = """
        a
        {{#if on}}
        b
        {{else}}
        c
        {{/if}}
        d
        """
        #expect(try render(template, flags: ["on"]) == "a\nb\nd")
        #expect(try render(template) == "a\nc\nd")
    }

    @Test func nestedBlocks() throws {
        let template = """
        {{#if outer}}
        {{#if inner}}
        both
        {{else}}
        outer only
        {{/if}}
        {{/if}}
        """
        #expect(try render(template, flags: ["outer", "inner"]) == "both")
        #expect(try render(template, flags: ["outer"]) == "outer only")
        #expect(try render(template, flags: ["inner"]).isEmpty)
    }

    @Test func conditions() throws {
        let context = TemplateContext(flags: ["a", "b"])
        #expect(try context.evaluate("a"))
        #expect(try !context.evaluate("!a"))
        #expect(try context.evaluate("c || b"))
        #expect(try !context.evaluate("a && c"))
        #expect(try context.evaluate("c || a && b"))
        #expect(throws: TemplateError.self) { try context.evaluate("a b") }
    }

    @Test func indentsMultilineValues() throws {
        let result = try render("enum E {\n    {{CASES}}\n}", variables: ["CASES": "case a\ncase b"])
        #expect(result == "enum E {\n    case a\n    case b\n}")
    }

    @Test func unbalancedBlocksThrow() {
        #expect(throws: TemplateError.unclosedBlock) { try render("{{#if a}}\nx") }
        #expect(throws: TemplateError.unbalancedBlock(line: 1)) { try render("{{/if}}") }
        #expect(throws: TemplateError.inlineBlock(line: 1)) { try render("x {{#if a}} y") }
    }

    @Test func pathComponents() throws {
        let context = TemplateContext(flags: ["tests"])
        #expect(try TemplateTree.resolve("[tests]AppNameTests", context: context, appName: "Demo") == "DemoTests")
        #expect(try TemplateTree.resolve("[!tests]Other", context: context, appName: "Demo") == nil)
        #expect(try TemplateTree.resolve("_.gitignore", context: context, appName: "Demo") == ".gitignore")
    }
}
