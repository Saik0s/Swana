@testable import Swana // Replace with your module name
import XCTest

class ParserTests: XCTestCase {
  func testGenericClass() {
    let testSource = """
    class GenericClass<T, U> {
      class NestedClass {
        let nestedProperty: Int
      }

      var genericProperty: (T, U)
      var nestedClassProperty: NestedClass

      init(genericProperty: (T, U), nestedClassProperty: NestedClass) {
        self.genericProperty = genericProperty
        self.nestedClassProperty = nestedClassProperty
      }

      func genericFunction(_ value: T) -> U {
        return genericProperty.1
      }
    }
    """

    _testParser(source: testSource, expectedOutput: [
      "GenericClass": TypeInformation(kind: "class", functions: [
        FunctionInformation(name: "init", returnType: "Void", argumentTypes: ["(T, U)", "NestedClass"], usedTypes: ["T", "U"]),
        FunctionInformation(name: "genericFunction", returnType: "U", argumentTypes: ["T"], usedTypes: ["T", "U"]),
      ], properties: [
        PropertyInformation(name: "genericProperty", type: "(T, U)"),
        PropertyInformation(name: "nestedClassProperty", type: "NestedClass"),
      ], usedTypes: ["NestedClass", "T", "U", "(T, U)"]),
      "NestedClass": TypeInformation(kind: "class", functions: [], properties: [
        PropertyInformation(name: "nestedProperty", type: "Int"),
      ], usedTypes: ["Int"]),
    ])
  }

  func testTrickyProtocol() {
    let testSource = """
    protocol TrickyProtocol {
      associatedtype Item
      associatedtype Result

      func processItems(_ items: [Item], completion: @escaping (Result) -> Void)
    }
    """

    _testParser(source: testSource, expectedOutput: [
      "TrickyProtocol": TypeInformation(kind: "protocol", functions: [
        FunctionInformation(
          name: "processItems",
          returnType: "Void",
          argumentTypes: ["[Item]", "@escaping (Result) -> Void"],
          usedTypes: ["Item", "Result", "Array"]
        ),
      ], properties: [], usedTypes: []),
    ])
  }

  private func _testParser(source: String, expectedOutput: [String: TypeInformation]) {
    let temporaryFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TemporaryFile.swift")
    try? source.write(to: temporaryFileURL, atomically: true, encoding: .utf8)

    let projectOverview = Parser.generateProjectOverview(at: temporaryFileURL)
    XCTAssertEqual(projectOverview.files.count, 1, "Project overview should have exactly 1 file")

    let fileOverview = projectOverview.files[temporaryFileURL]!
    XCTAssertNotNil(fileOverview, "File overview should not be nil")

    let types = fileOverview.types
    XCTAssertEqual(
      types.count,
      expectedOutput.count,
      "Parsed types (\(types.keys.joined(separator: ", "))) count should match the expected (\(expectedOutput.keys.joined(separator: ", "))) count"
    )

    for (typeName, expectedTypeInfo) in expectedOutput {
      guard let typeInfo = types[typeName] else {
        XCTFail("Type \(typeName) not found in the output")
        continue
      }

      XCTAssertEqual(typeInfo.kind, expectedTypeInfo.kind, "Type kind for \(typeName) should match the expected kind")
      XCTAssertEqual(typeInfo.functions.count, expectedTypeInfo.functions.count, "Functions count for \(typeName) should match the expected count")
      XCTAssertEqual(typeInfo.properties.count, expectedTypeInfo.properties.count, "Properties count for \(typeName) should match the expected count")
      XCTAssertEqual(typeInfo.usedTypes, expectedTypeInfo.usedTypes, "Used types for \(typeName) should match the expected used types")

      for (index, functionInfo) in typeInfo.functions.enumerated() {
        let expectedFunctionInfo = expectedTypeInfo.functions[index]
        XCTAssertEqual(functionInfo.name, expectedFunctionInfo.name, "Function name for \(typeName) at index \(index) should match the expected name")
        XCTAssertEqual(
          functionInfo.returnType,
          expectedFunctionInfo.returnType,
          "Return type for \(functionInfo.name) should match the expected return type"
        )
        XCTAssertEqual(
          functionInfo.argumentTypes,
          expectedFunctionInfo.argumentTypes,
          "Argument types for \(functionInfo.name) should match the expected argument types"
        )
        XCTAssertEqual(
          functionInfo.usedTypes,
          expectedFunctionInfo.usedTypes,
          "Used types for \(functionInfo.name) should match the expected used types"
        )
      }

      for (index, propertyInfo) in typeInfo.properties.enumerated() {
        let expectedPropertyInfo = expectedTypeInfo.properties[index]
        XCTAssertEqual(propertyInfo.name, expectedPropertyInfo.name, "Property name for \(typeName) at index \(index) should match the expected name")
        XCTAssertEqual(propertyInfo.type, expectedPropertyInfo.type, "Property type for \(propertyInfo.name) should match the expected type")
      }
    }
  }
}
