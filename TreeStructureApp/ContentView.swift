import SwiftUI

struct ContentView: View {
    @State private var path: String = ""
    @State private var treeStructure: String = ""
    @State private var isImporting: Bool = false

    var body: some View {
        VStack {
            TextField("Enter path or browse...", text: $path)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                Button("Browse") {
                    isImporting = true
                }
                .buttonStyle(.bordered)

                Button("Generate") {
                    self.treeStructure = generateTreeStructure(fromPath: self.path)
                }
                .buttonStyle(.borderedProminent)
            }

            ScrollView {
                Text(treeStructure)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.folder]) { result in
            switch result {
            case .success(let selectedFolder):
                self.path = selectedFolder.path
            case .failure(let error):
                print("Error selecting folder: \(error.localizedDescription)")
            }
        }
    }

    private func generateTreeStructure(fromPath path: String) -> String {
        var treeStructure = ""
        getTreeStructureRecursive(path, indentLevel: 1, treeStructure: &treeStructure)
        return treeStructure
    }

    private func getTreeStructureRecursive(_ path: String, indentLevel: Int, treeStructure: inout String) {
        let fileManager = FileManager.default
        do {
            let fileURLs = try fileManager.contentsOfDirectory(atPath: path)
            for file in fileURLs {
                let fullPath = "\(path)/\(file)"
                var isDir: ObjCBool = false
                
                if fileManager.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue {
                    // Skip node_modules and .git directories
                    if file != "node_modules" && file != ".git" {
                        treeStructure += String(repeating: " ", count: 4 * indentLevel) + "|-- \(file)\n"
                        getTreeStructureRecursive(fullPath, indentLevel: indentLevel + 1, treeStructure: &treeStructure)
                    }
                } else {
                    // Process files
                    treeStructure += String(repeating: " ", count: 4 * indentLevel) + "|   \(file)\n"
                }
            }
        } catch {
            print("Error accessing path \(path): \(error)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
