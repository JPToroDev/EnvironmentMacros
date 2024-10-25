import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct EnvironmentMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EnvironmentBodyBuilderMacro.self,
    ]
}

public struct EnvironmentBodyBuilderMacro {}

extension EnvironmentBodyBuilderMacro: MemberMacro {
    public static func expansion<
        Declaration, Context
    >(
        of node: AttributeSyntax,
        attachedTo declaration: Declaration,
        providingMembersOf decl: some DeclGroupSyntax,
        in context: inout Context
    ) throws -> [DeclSyntax]
    where Declaration: DeclSyntaxProtocol, Context: MacroExpansionContext {
        // Find the 'body' function
        guard let structDecl = decl.as(StructDeclSyntax.self) else {
            return []
        }

        guard let bodyFunc = structDecl.memberBlock.members.compactMap({ member in
            member.decl.as(FunctionDeclSyntax.self)
        }).first(where: { $0.identifier.text == "body" }) else {
            return []
        }

        // Process the 'body' function
        let transformedBodyFunc = try processBodyFunction(bodyFunc, context: context)

        // Return the transformed 'body' function
        return [DeclSyntax(transformedBodyFunc)]
    }

    static func processBodyFunction(
        _ funcDecl: FunctionDeclSyntax,
        context: inout some MacroExpansionContext
    ) throws -> FunctionDeclSyntax {
        guard let body = funcDecl.body else {
            return funcDecl
        }

        let transformer = EnvironmentTransformer()
        let newBody = transformer.visit(body).as(CodeBlockSyntax.self)!

        return funcDecl.withBody(newBody)
    }
}

class EnvironmentTransformer: SyntaxRewriter {
    override func visit(_ node: IfStmtSyntax) -> StmtSyntax {
        // Check if the condition involves an @Environment variable
        if let condition = node.conditions.first?.condition,
           let binaryExpr = condition.as(BinaryExprSyntax.self),
           let leftExpr = binaryExpr.leftOperand.as(IdentifierExprSyntax.self),
           let envVarName = extractEnvironmentVariableName(from: leftExpr),
           let rightExpr = binaryExpr.rightOperand {

            // Get the environment variable key
            let key = envVarName

            // Extract possible values from the right expression
            let value = rightExpr.description.trimmingCharacters(in: .whitespacesAndNewlines)

            // Process then branch
            let thenStatements = wrapStatements(node.body.statements, key: key, value: value)

            // Process else branch
            var elseStatements = CodeBlockItemListSyntax([])

            if let elseBody = node.elseBody {
                if let elseCodeBlock = elseBody.as(CodeBlockSyntax.self) {
                    elseStatements = wrapStatements(elseCodeBlock.statements, key: key, value: "NOT_\(value)")
                } else if let elseIfStmt = elseBody.as(IfStmtSyntax.self) {
                    elseStatements = CodeBlockItemListSyntax([CodeBlockItemSyntax(item: Syntax(visit(elseIfStmt)), semicolon: nil)])
                }
            }

            // Combine then and else statements
            let combinedStatements = thenStatements.appending(contentsOf: elseStatements)

            // Return a code block containing both branches
            return StmtSyntax(CodeBlockSyntax(statements: combinedStatements))
        }

        return super.visit(node)
    }

    func extractEnvironmentVariableName(from identifier: IdentifierExprSyntax) -> String? {
        // Assuming that environment variables are properties of the struct
        return identifier.identifier.text
    }

    func wrapStatements(
        _ statements: CodeBlockItemListSyntax,
        key: String,
        value: String
    ) -> CodeBlockItemListSyntax {
        // Wrap each statement with .addEnvironmentCondition(key:value:)
        return statements.map { statement in
            if let exprStmt = statement.item.as(ExprStmtSyntax.self) {
                let modifiedExprStmt = exprStmt.addEnvironmentCondition(key: key, value: value)
                return statement.withItem(Syntax(modifiedExprStmt))
            } else {
                return statement
            }
        }
    }
}

extension ExprStmtSyntax {
    func addEnvironmentCondition(key: String, value: String) -> ExprStmtSyntax {
        guard let callExpr = self.expression.as(FunctionCallExprSyntax.self) else {
            return self
        }

        let newExpr = callExpr.addEnvironmentConditionCall(key: key, value: value)
        return self.withExpression(ExprSyntax(newExpr))
    }
}

extension FunctionCallExprSyntax {
    func addEnvironmentConditionCall(key: String, value: String) -> FunctionCallExprSyntax {
        let newCalledExpression = MemberAccessExprSyntax(
            base: self.calledExpression,
            dot: .periodToken(),
            name: .identifier("addEnvironmentCondition")
        )

        let newArgumentList = FunctionCallArgumentListSyntax([
            FunctionCallArgumentSyntax(
                label: .identifier("key"),
                colon: .colonToken(),
                expression: ExprSyntax(StringLiteralExprSyntax(content: key)),
                trailingComma: .commaToken()
            ),
            FunctionCallArgumentSyntax(
                label: .identifier("value"),
                colon: .colonToken(),
                expression: ExprSyntax(StringLiteralExprSyntax(content: value)),
                trailingComma: nil
            )
        ])

        return self.withCalledExpression(ExprSyntax(newCalledExpression))
            .withArgumentList(newArgumentList)
    }
}
