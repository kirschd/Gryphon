/*
* Copyright 2018 Vinícius Jorge Vendramini
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation
import GryphonLib

func updateFiles(
    in folder: String,
    from originExtension: String,
    to destinationExtension: String,
    with closure: (String, String) -> ())
{
    let currentURL = URL(fileURLWithPath: Process().currentDirectoryPath + "/" + folder)
    let fileURLs = try! FileManager.default.contentsOfDirectory(
        at: currentURL,
        includingPropertiesForKeys: nil)
    let testFiles = fileURLs.filter { $0.pathExtension == originExtension }

    for originFile in testFiles {
        let originFilePath = originFile.path
        let destinationFilePath =
            GRYUtils.changeExtension(of: originFilePath, to: destinationExtension)

        let destinationFileWasJustCreated =
            GRYUtils.createFileIfNeeded(at: destinationFilePath, containing: "")
        let destinationFileIsOutdated = destinationFileWasJustCreated ||
            GRYUtils.file(originFilePath, wasModifiedLaterThan: destinationFilePath)

        if destinationFileIsOutdated {
            print("\tUpdating \(destinationFilePath)...")
            closure(originFilePath, destinationFilePath)
        }
    }
}

func updateFiles(inFolder folder: String) {
    updateFiles(in: folder, from: "swift", to: "ast")
    { (_: String, astFilePath: String) in
        fatalError("Please update ast file \(astFilePath) with the `dump-ast.pl` perl script.")
    }

    updateFiles(in: folder, from: "ast", to: "json")
    { (astFilePath: String, jsonFilePath: String) in
        let ast = GRYAst(astFile: astFilePath)
        ast.writeAsJSON(toFile: jsonFilePath)
    }

    updateFiles(in: folder, from: "json", to: "expectedJson")
    { (jsonFilePath: String, expectedJsonFilePath: String) in
        let jsonContents = try! String(contentsOfFile: jsonFilePath)
        let expectedJsonURL = URL(fileURLWithPath: expectedJsonFilePath)
        try! jsonContents.write(to: expectedJsonURL, atomically: false, encoding: .utf8)
    }
}

func main() {
    updateFiles(inFolder: "Test Files")
    updateFiles(inFolder: "Example ASTs")

//	let filePath = Process().currentDirectoryPath + "/Test Files/<#testFile#>.swift"
    let filePath = Process().currentDirectoryPath + "/Example ASTs/<#testFile#>"

//	print(GRYCompiler.getSwiftASTDump(forFileAt: filePath))
//	print(GRYCompiler.generateAST(forFileAt: filePath).description(withHorizontalLimit: 100))
//    print(GRYCompiler.processExternalAST(filePath))
	let (code, diagnostics, ast) =
		GRYCompiler.generateKotlinCodeWithDiagnostics(forFileAt: filePath)
	print(ast.description(withHorizontalLimit: 100))
	print(code)
	print(diagnostics)
//	print(GRYCompiler.compileAndRun(fileAt: filePath))
}

main()
