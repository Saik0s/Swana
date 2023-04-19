<div align="center" style="font-family: monospace;">
<span style="color: blue; font-weight: bold;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>
<span style="color: blue; font-weight: bold;">&nbsp;@@@@@@&nbsp;&nbsp;&nbsp;@@@&nbsp;&nbsp;@@@&nbsp;&nbsp;@@@&nbsp;&nbsp;&nbsp;@@@@@@&nbsp;&nbsp;&nbsp;@@@&nbsp;&nbsp;@@@&nbsp;&nbsp;&nbsp;@@@@@@&nbsp;&nbsp;&nbsp;</span>
<span style="color: blue; font-weight: bold;">@@@@@@@&nbsp;&nbsp;&nbsp;@@@&nbsp;&nbsp;@@@&nbsp;&nbsp;@@@&nbsp;&nbsp;@@@@@@@@&nbsp;&nbsp;@@@@&nbsp;@@@&nbsp;&nbsp;@@@@@@@@&nbsp;&nbsp;</span>
<span style="color: blue; font-weight: bold;">!@@&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;@@!&nbsp;&nbsp;@@!&nbsp;&nbsp;@@!&nbsp;&nbsp;@@!&nbsp;&nbsp;@@@&nbsp;&nbsp;@@!@!@@@&nbsp;&nbsp;@@!&nbsp;&nbsp;@@@&nbsp;&nbsp;</span>
<span style="color: blue; font-weight: bold;">!@!&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;!@!&nbsp;&nbsp;!@!&nbsp;&nbsp;!@!&nbsp;&nbsp;!@!&nbsp;&nbsp;@!@&nbsp;&nbsp;!@!!@!@!&nbsp;&nbsp;!@!&nbsp;&nbsp;@!@&nbsp;&nbsp;</span>
<span style="color: blue; font-weight: bold;">!!@@!!&nbsp;&nbsp;&nbsp;&nbsp;@!!&nbsp;&nbsp;!!@&nbsp;&nbsp;@!@&nbsp;&nbsp;@!@!@!@!&nbsp;&nbsp;@!@&nbsp;!!@!&nbsp;&nbsp;@!@!@!@!&nbsp;&nbsp;</span>
<span style="color: yellow; font-weight: bold;">&nbsp;!!@!!!&nbsp;&nbsp;&nbsp;!@!&nbsp;&nbsp;!!!&nbsp;&nbsp;!@!&nbsp;&nbsp;!!!@!!!!&nbsp;&nbsp;!@!&nbsp;&nbsp;!!!&nbsp;&nbsp;!!!@!!!!&nbsp;&nbsp;</span>
<span style="color: yellow; font-weight: bold;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;!:!&nbsp;&nbsp;!!:&nbsp;&nbsp;!!:&nbsp;&nbsp;!!:&nbsp;&nbsp;!!:&nbsp;&nbsp;!!!&nbsp;&nbsp;!!:&nbsp;&nbsp;!!!&nbsp;&nbsp;!!:&nbsp;&nbsp;!!!&nbsp;&nbsp;</span>
<span style="color: yellow; font-weight: bold;">&nbsp;&nbsp;&nbsp;&nbsp;!:!&nbsp;&nbsp;&nbsp;:!:&nbsp;&nbsp;:!:&nbsp;&nbsp;:!:&nbsp;&nbsp;:!:&nbsp;&nbsp;!:!&nbsp;&nbsp;:!:&nbsp;&nbsp;!:!&nbsp;&nbsp;:!:&nbsp;&nbsp;!:!&nbsp;&nbsp;</span>
<span style="color: yellow; font-weight: bold;">::::&nbsp;::&nbsp;&nbsp;&nbsp;&nbsp;::::&nbsp;::&nbsp;:::&nbsp;&nbsp;&nbsp;::&nbsp;&nbsp;&nbsp;:::&nbsp;&nbsp;&nbsp;::&nbsp;&nbsp;&nbsp;::&nbsp;&nbsp;::&nbsp;&nbsp;&nbsp;:::&nbsp;&nbsp;</span>
<span style="color: yellow; font-weight: bold;">::&nbsp;:&nbsp;:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;::&nbsp;:&nbsp;&nbsp;:&nbsp;:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;:&nbsp;&nbsp;&nbsp;:&nbsp;:&nbsp;&nbsp;::&nbsp;&nbsp;&nbsp;&nbsp;:&nbsp;&nbsp;&nbsp;&nbsp;:&nbsp;&nbsp;&nbsp;:&nbsp;:&nbsp;&nbsp;</span>
<span style="color: yellow; font-weight: bold;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>
</div>

# Swana

Swana is a Swift project analyzer that generates an overview of your Swift project, including information about types, functions, properties, and used types.

## Features

- Analyzes Swift source files in a given project folder
- Generates an overview of types, functions, properties, and used types
- Supports classes, structs, enums, and protocols
- Prints the project overview in a human-readable format

## Requirements

- macOS 13.0 or later
- Swift 5.7 or later

## Installation

1. Clone the repository:

    ```sh
    git clone https://github.com/yourusername/swana.git
    ```

2. Build the project:

    ```sh
    swift build -c release
    ```

3. Copy the executable to your desired location:

    ```sh
    cp .build/release/Swana /usr/local/bin/swana
    ```

## Usage

To analyze a Swift project, simply run the `swana` command followed by the path to your project folder:

```sh
swana /path/to/your/swift/project
```

Swana will then generate and print an overview of your project, including information about types, functions, properties, and used types.

## Example Output

```sh
Files: /path/to/your/swift/project
    File: SourceFile.swift
        TypeName (class)
        ├───Functions:
        │ ├───functionName
        │ │ ├───Argument Types: Type1, Type2
        │ │ ├───Return Type: ReturnType
        │ │ └───Used Types: Type1, Type2, ReturnType
        └───Properties:
        │ └───propertyName: PropertyType
        └───Used Types: Type1, Type2, ReturnType, PropertyType
```

### Architecture

1. `ProjectOverview class`: Represents an overview of a project, containing a URL for the project and dictionaries for the files and folders. Each file is represented by a `FileOverview` object, with information about types, functions, and symbols in the file.

2. `TypeInformation class`: Represents information about a type, including its kind (class, struct, enum, or protocol), functions, properties, and used types.

3. `FunctionInformation class`: Represents information about a function, including its name, return type, argument types, and used types.

4. `PropertyInformation struct`: Represents information about a property, including its name and type.

5. `Parser enum`: Contains static functions for generating a project overview and analyzing a source file.
   - `generateProjectOverview`: Takes a URL for a project folder and returns a `ProjectOverview` object representing the project.
   - `analyzeSourceFile`: Takes a `SourceFileSyntax` object and returns a `FileOverview` object representing the file.
   - `printProjectOverview`: Takes a `ProjectOverview` object and prints information about the project to the console.

6. `SourceFileVisitor class`: A `SyntaxVisitor` subclass that visits the nodes in a source file's syntax tree and extracts information about the types, functions, and properties in the file. It maintains a stack of type names as it visits the nodes and uses this information to build up the `ProjectOverview` and `FileOverview` objects.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
