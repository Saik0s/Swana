import ANSITerminal
import Foundation
import SwiftSyntax
import SwiftSyntaxParser

// MARK: - ProjectOverview

class ProjectOverview {
  var files: [URL: FileOverview] = [:]
  var folders: [URL] = []
}

// MARK: - FileOverview

class FileOverview {
  var types: [String: TypeInformation] = [:]
  var functions: [String: Int] = [:]
  var symbols: [String: Int] = [:]
}

// MARK: - TypeInformation

class TypeInformation {
  let kind: String
  var functions: [FunctionInformation] = []
  var properties: [PropertyInformation] = []
  var usedTypes: Set<String> = []

  init(kind: String) {
    self.kind = kind
  }
}

// MARK: - FunctionInformation

class FunctionInformation {
  let name: String
  let returnType: String
  let argumentTypes: [String]
  var usedTypes: Set<String> = []

  init(name: String, returnType: String, argumentTypes: [String]) {
    self.name = name
    self.returnType = returnType
    self.argumentTypes = argumentTypes
  }
}

// MARK: - PropertyInformation

struct PropertyInformation {
  let name: String
  let type: String
}

// MARK: - Parser

enum Parser {
  static func generateProjectOverview(at url: URL) -> ProjectOverview {
    let projectOverview = ProjectOverview()

    do {
      let fileManager = FileManager.default
      let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey]
      let directoryEnumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: Array(resourceKeys))

      while let fileURL = directoryEnumerator?.nextObject() as? URL {
        if fileURL.pathExtension == "swift" {
          let sourceFile = try SyntaxParser.parse(fileURL)
          let fileOverview = analyzeSourceFile(sourceFile)
          projectOverview.files[fileURL] = fileOverview
        } else if let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                  let isDirectory = resourceValues.allValues[.isDirectoryKey] as? Bool,
                  isDirectory {
          projectOverview.folders.append(fileURL)
        }
      }
    } catch {
      print("Error: \(error.localizedDescription)".red)
    }

    return projectOverview
  }

  static func analyzeSourceFile(_ sourceFile: SourceFileSyntax) -> FileOverview {
    let fileOverview = FileOverview()
    let visitor = SourceFileVisitor(fileOverview: fileOverview)
    visitor.walk(sourceFile)
    return fileOverview
  }

  static func printProjectOverview(_ overview: ProjectOverview) {
    print("\nFiles:")
    for (fileURL, fileOverview) in overview.files {
      print("\nFile: \(fileURL.lastPathComponent)")
      print("\n  Types:")
      for (typeName, typeInfo) in fileOverview.types {
        print("    \(typeName) (\(typeInfo.kind))")
        print("      Functions:")
        for functionInfo in typeInfo.functions {
          let argumentList = zip(functionInfo.argumentTypes, functionInfo.argumentTypes).map { "\($0): \($1)" }.joined(separator: ", ")
          print(
            "        \(functionInfo.name)(\(argumentList)) -> Return Type: \(functionInfo.returnType) -> Used Types: \(functionInfo.usedTypes.sorted().joined(separator: ", "))"
          )
        }
        print("      Properties:")
        for propertyInfo in typeInfo.properties {
          print("        \(propertyInfo.name): \(propertyInfo.type)")
        }
        print("      Used Types: \(typeInfo.usedTypes.sorted().joined(separator: ", "))")
      }
    }
  }
}

// MARK: - SourceFileVisitor

class SourceFileVisitor: SyntaxVisitor {
  var fileOverview: FileOverview
  var currentTypeName: String?
  var currentFunctionName: String?

  init(fileOverview: FileOverview) {
    self.fileOverview = fileOverview
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
    if let currentType = currentTypeName,
       let typeInfo = fileOverview.types[currentType] {
      let functionName = node.identifier.text

      let returnType = node.signature.output?.returnType.description.trimmingCharacters(in: .whitespaces) ?? "Void"
      if isValidTypeName(returnType) {
        typeInfo.usedTypes.insert(returnType)
      }

      let argumentTypes = node.signature.input.parameterList.compactMap { param -> String? in
        let paramType = param.type?.description.trimmingCharacters(in: .whitespaces)
        if let type = paramType, isValidTypeName(type) {
          typeInfo.usedTypes.insert(type)
        }
        return paramType
      }

      let functionInfo = FunctionInformation(name: functionName, returnType: returnType, argumentTypes: argumentTypes)
      typeInfo.functions.append(functionInfo)
      currentFunctionName = functionName
      fileOverview.types[currentType] = typeInfo
    }
    return .visitChildren
  }

  override func visit(_ node: PatternBindingListSyntax) -> SyntaxVisitorContinueKind {
    guard let currentType = currentTypeName,
          let typeInfo = fileOverview.types[currentType] else {
      return .visitChildren
    }
    for binding in node {
      if let typeAnnotation = binding.typeAnnotation {
        let propertyName = binding.pattern.description.trimmingCharacters(in: .whitespaces)
        let propertyType = typeAnnotation.type.description.trimmingCharacters(in: .whitespaces)
        if !propertyName.isKeywordOrLiteral() && isValidTypeName(propertyType) {
          let propertyInfo = PropertyInformation(name: propertyName, type: propertyType)
          typeInfo.properties.append(propertyInfo)
          typeInfo.usedTypes.insert(propertyType)
          fileOverview.types[currentType] = typeInfo
        }
      }
    }
    return .visitChildren
  }

  override func visit(_ node: TypeInheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
    guard let typeName = currentTypeName else { return .skipChildren }

    for inheritedType in node.inheritedTypeCollection {
      let inheritedTypeName = inheritedType.typeName.description.trimmingCharacters(in: .whitespaces)
      if !inheritedTypeName.isKeywordOrLiteral() && fileOverview.types[typeName]?.usedTypes != nil {
        fileOverview.types[typeName]?.usedTypes.insert(inheritedTypeName)
      }
    }

    return .skipChildren
  }

  override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
    let accessedType = node.name.text.trimmingCharacters(in: .whitespaces)
    if let currentType = currentTypeName,
       let typeInfo = fileOverview.types[currentType],
       isValidTypeName(accessedType) {
      typeInfo.usedTypes.insert(accessedType)
      fileOverview.types[currentType] = typeInfo
    }

    return .skipChildren
  }

  override func visit(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
    let typeName = node.type.description.trimmingCharacters(in: .whitespaces)
    if let currentType = currentTypeName,
       let typeInfo = fileOverview.types[currentType] {
      let extractedTypes = extractTypes(from: typeName)
      for extractedType in extractedTypes {
        if isValidTypeName(extractedType) {
          typeInfo.usedTypes.insert(extractedType)
          fileOverview.types[currentType] = typeInfo
        }
      }
    }

    return .skipChildren
  }

  private func extractTypes(from typeName: String) -> Set<String> {
    var types: Set<String> = []
    var currentType = ""
    var angleBracketDepth = 0

    for character in typeName {
      switch character {
      case "<":
        if angleBracketDepth == 0 {
          types.insert(currentType)
          currentType = ""
        } else {
          currentType.append(character)
        }
        angleBracketDepth += 1
      case ">":
        angleBracketDepth -= 1
        if angleBracketDepth == 0 {
          types.insert(currentType)
          currentType = ""
        } else {
          currentType.append(character)
        }
      case ",":
        if angleBracketDepth == 1 {
          types.insert(currentType.trimmingCharacters(in: .whitespaces))
          currentType = ""
        } else {
          currentType.append(character)
        }
      default:
        currentType.append(character)
      }
    }

    if !currentType.isEmpty {
      types.insert(currentType.trimmingCharacters(in: .whitespaces))
    }

    return types
  }

  private func processTypeDeclaration(_ node: SyntaxProtocol, typeKind: String) {
    var typeName = ""
    if let classNode = node as? ClassDeclSyntax {
      typeName = classNode.identifier.text
    } else if let structNode = node as? StructDeclSyntax {
      typeName = structNode.identifier.text
    } else if let enumNode = node as? EnumDeclSyntax {
      typeName = enumNode.identifier.text
    } else if let protocolNode = node as? ProtocolDeclSyntax {
      typeName = protocolNode.identifier.text
    }

    if !typeName.isEmpty && !typeName.isKeywordOrLiteral() {
      let typeInfo = TypeInformation(kind: typeKind)
      fileOverview.types[typeName] = typeInfo
      currentTypeName = typeName
    }
  }

  private func isValidTypeName(_ typeName: String) -> Bool {
    !typeName.isKeywordOrLiteral() && (typeName.first?.isUppercase == true || typeName.first == "[")
  }
}

extension String {
  func isKeywordOrLiteral() -> Bool {
    let keywordsAndLiterals: Set<String> = [
      "self", "super", "nil", "true", "false",
    ]
    return keywordsAndLiterals.contains(self)
  }
}
