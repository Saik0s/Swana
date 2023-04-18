import ANSITerminal
import Foundation
import SwiftSyntax
import SwiftSyntaxParser

// MARK: - ProjectOverview

class ProjectOverview {
  var types: [String: TypeInformation] = [:]
  var functions: [String: Int] = [:]
  var symbols: [String: Int] = [:]
  var files: [URL] = []
  var folders: [URL] = []
  var dependencies: [String: Set<String>] = [:]
}

// MARK: - TypeInformation

struct TypeInformation {
  var kind: String
  var functions: [String]
}

// MARK: - Parser

enum Parser {
  static func generateProjectOverview(at url: URL, projectOverview: ProjectOverview) {
    do {
      let fileManager = FileManager.default
      let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey]
      let directoryEnumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: Array(resourceKeys))

      while let fileURL = directoryEnumerator?.nextObject() as? URL {
        if fileURL.pathExtension == "swift" {
          projectOverview.files.append(fileURL)
          let sourceFile = try SyntaxParser.parse(fileURL)
          analyzeSourceFile(sourceFile, projectOverview: projectOverview)
        } else if let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                  let isDirectory = resourceValues.allValues[.isDirectoryKey] as? Bool,
                  isDirectory {
          projectOverview.folders.append(fileURL)
        }
      }
    } catch {
      print("Error: \(error.localizedDescription)")
    }
  }

  static func analyzeSourceFile(_ sourceFile: SourceFileSyntax, projectOverview: ProjectOverview) {
    let visitor = SourceFileVisitor(projectOverview: projectOverview)
    visitor.walk(sourceFile)
  }

  static func printProjectOverview(_ overview: ProjectOverview) {
    print("\nProject Overview:")

    print("\nFiles:".blue.bold)
    for file in overview.files {
      print("  \(file.path.green)")
    }

    print("\nFolders:".blue.bold)
    for folder in overview.folders {
      print("  \(folder.path.green)")
    }

    print("\nTypes:".blue.bold)
    for (typeName, typeInfo) in overview.types {
      print("  \(typeInfo.kind.green) \(typeName.darkGray)")
    }

    print("\nFunctions:".blue.bold)
    for (funcName, funcCount) in overview.functions {
      print("  \(funcName.green)", "(occurrences: \(funcCount))".darkGray)
    }

    print("\nSymbols:".blue.bold)
    for (symbolName, symbolCount) in overview.symbols {
      print("  \(symbolName.green)", "(occurrences: \(symbolCount))".darkGray)
    }

    print("\nDependencies:".blue.bold)
    for (typeName, dependencies) in overview.dependencies {
      print("  \(typeName.green) -> \(dependencies.joined(separator: ", ").green)")
    }
  }
}

// MARK: - SourceFileVisitor

class SourceFileVisitor: SyntaxVisitor {
  var projectOverview: ProjectOverview
  var currentTypeName: String?

  init(projectOverview: ProjectOverview) {
    self.projectOverview = projectOverview
    super.init(viewMode: .sourceAccurate)
  }

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    processTypeDeclaration(node, typeKind: "class")
    return .visitChildren
  }

  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    processTypeDeclaration(node, typeKind: "struct")
    return .visitChildren
  }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    processTypeDeclaration(node, typeKind: "enum")
    return .visitChildren
  }

  override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    processTypeDeclaration(node, typeKind: "protocol")
    return .visitChildren
  }

  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    let functionName = node.identifier.text
    projectOverview.functions[functionName, default: 0] += 1
    return .visitChildren
  }

  override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    let bindings = node.bindings
    for binding in bindings {
      if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
        let symbolName = identifier.identifier.text
        projectOverview.symbols[symbolName, default: 0] += 1
      }
    }
    return .visitChildren
  }

  override func visit(_ node: TypeInheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
    guard let typeName = currentTypeName else { return .skipChildren }

    for inheritedType in node.inheritedTypeCollection {
      let inheritedTypeName = inheritedType.typeName.description.trimmingCharacters(in: .whitespaces)
      projectOverview.dependencies[typeName, default: []].insert(inheritedTypeName)
    }

    return .skipChildren
  }

  private func processTypeDeclaration(_ node: some SyntaxProtocol, typeKind: String) {
    if let typeIdentifier = getTypeIdentifier(from: node) {
      let typeName = typeIdentifier.text
      if projectOverview.types[typeName] == nil {
        projectOverview.types[typeName] = TypeInformation(kind: typeKind, functions: [])
      }
      currentTypeName = typeName
    }
  }

  private func getTypeIdentifier(from node: SyntaxProtocol) -> TokenSyntax? {
    switch node {
    case let classDecl as ClassDeclSyntax:
      return classDecl.identifier
    case let structDecl as StructDeclSyntax:
      return structDecl.identifier
    case let enumDecl as EnumDeclSyntax:
      return enumDecl.identifier
    case let protocolDecl as ProtocolDeclSyntax:
      return protocolDecl.identifier
    default:
      return nil
    }
  }
}
