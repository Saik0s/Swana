import ANSITerminal
import Foundation
import SwiftSyntax
import SwiftSyntaxParser

// MARK: - ProjectOverview

class ProjectOverview {
  var url: URL
  var files: [URL: FileOverview] = [:]
  var folders: [URL] = []

  init(url: URL, files: [URL: FileOverview] = [:], folders: [URL] = []) {
    self.url = url
    self.files = files
    self.folders = folders
  }
}

// MARK: - FileOverview

class FileOverview {
  var types: [String: TypeInformation] = [:]
  var functions: [String: Int] = [:]
  var symbols: [String: Int] = [:]

  init(types: [String: TypeInformation] = [:], functions: [String: Int] = [:], symbols: [String: Int] = [:]) {
    self.types = types
    self.functions = functions
    self.symbols = symbols
  }
}

// MARK: - TypeInformation

class TypeInformation {
  let kind: String
  var functions: [FunctionInformation] = []
  var properties: [PropertyInformation] = []
  var usedTypes: Set<String> = []

  init(kind: String, functions: [FunctionInformation] = [], properties: [PropertyInformation] = [], usedTypes: Set<String> = []) {
    self.kind = kind
    self.functions = functions
    self.properties = properties
    self.usedTypes = usedTypes
  }
}

// MARK: - FunctionInformation

class FunctionInformation {
  let name: String
  let returnType: String
  let argumentTypes: [String]
  var usedTypes: Set<String> = []

  init(name: String, returnType: String, argumentTypes: [String], usedTypes: Set<String> = []) {
    self.name = name
    self.returnType = returnType
    self.argumentTypes = argumentTypes
    self.usedTypes = usedTypes
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
    let projectOverview = ProjectOverview(url: url)

    do {
      let fileManager = FileManager.default
      let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey]

      if url.pathExtension == "swift" {
        let sourceFile = try SyntaxParser.parse(url)
        let fileOverview = analyzeSourceFile(sourceFile)
        projectOverview.files[url] = fileOverview
      } else {
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
    print("\nFiles:".lightGreen, "\(overview.url.relativePath)".blue)
    for (fileURL, fileOverview) in overview.files {
      print("     File:".darkGray, "\(fileURL.absoluteString.trimmingPrefix(overview.url.absoluteString))".blue)
      for (typeName, typeInfo) in fileOverview.types {
        print("         ".darkGray, "\(typeName.yellow.bold) (\(typeInfo.kind))", separator: "")
        print("         ├───Functions:".darkGray)
        for functionInfo in typeInfo.functions {
          let argumentList = functionInfo.argumentTypes.joined(separator: ", ")
          print("         │   ├───\(functionInfo.name.yellow.bold)".green)
          print("         │   │   ├───Argument Types:".darkGray, "\(argumentList)".lightMagenta)
          print("         │   │   ├───Return Type:".darkGray, "\(functionInfo.returnType)".lightMagenta)
          print("         │   │   └───Used Types:".darkGray, "\(functionInfo.usedTypes.sorted().joined(separator: ", "))".lightMagenta)
        }
        print("         └───Properties:".darkGray)
        for propertyInfo in typeInfo.properties {
          print("         │   └───".darkGray, "\(propertyInfo.name.yellow.bold): \(propertyInfo.type.lightMagenta)", separator: "")
        }
        print("         └───Used Types:".darkGray, "\(typeInfo.usedTypes.sorted().joined(separator: ", "))".lightMagenta)
      }
    }
  }
}

// MARK: - SourceFileVisitor

class SourceFileVisitor: SyntaxVisitor {
  var fileOverview: FileOverview
  var typeNameStack: [String] = []
  var currentFunctionName: String?
  var currentFunctionInfo: FunctionInformation?

  init(fileOverview: FileOverview) {
    self.fileOverview = fileOverview
    super.init(viewMode: .all)
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
      currentFunctionInfo = functionInfo
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

  override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    if let currentType = currentTypeName,
       let typeInfo = fileOverview.types[currentType] {
      let functionName = "init"

      let argumentTypes = node.signature.input.parameterList.compactMap { param -> String? in
        param.type?.description.trimmingCharacters(in: .whitespaces)
      }

      let functionInfo = FunctionInformation(name: functionName, returnType: "Void", argumentTypes: argumentTypes)
      typeInfo.functions.append(functionInfo)
      currentFunctionName = functionName
      currentFunctionInfo = functionInfo
      fileOverview.types[currentType] = typeInfo
    }
    return .visitChildren
  }

  override func visit(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
    let typeName = node.type.description.trimmingCharacters(in: .whitespaces)
    if let currentType = currentTypeName,
       let typeInfo = fileOverview.types[currentType] {
      let types = extractTypes(from: typeName)
      typeInfo.usedTypes.formUnion(types)
      fileOverview.types[currentType] = typeInfo
    }

    if let functionInfo = currentFunctionInfo {
      let types = extractTypes(from: typeName)
      functionInfo.usedTypes.formUnion(types)
      currentFunctionInfo = functionInfo
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
      typeNameStack.append(typeName)
    }
  }

  private func leaveTypeDeclaration() {
    typeNameStack.removeLast()
  }

  override func visitPost(_: ClassDeclSyntax) {
    leaveTypeDeclaration()
  }

  override func visitPost(_: StructDeclSyntax) {
    leaveTypeDeclaration()
  }

  override func visitPost(_: EnumDeclSyntax) {
    leaveTypeDeclaration()
  }

  override func visitPost(_: ProtocolDeclSyntax) {
    leaveTypeDeclaration()
  }

  override func visitPost(_: FunctionDeclSyntax) {
    currentFunctionInfo = nil
  }

  override func visitPost(_: InitializerDeclSyntax) {
    currentFunctionInfo = nil
  }

  private var currentTypeName: String? {
    typeNameStack.last
  }

  private func isValidTypeName(_ typeName: String) -> Bool {
    !typeName.isKeywordOrLiteral() && (typeName.first?.isUppercase == true || typeName.first == "[" || typeName.first == "(")
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
