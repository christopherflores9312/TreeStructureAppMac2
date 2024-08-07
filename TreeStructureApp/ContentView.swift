import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @State private var folderURL: URL?
    @State private var treeStructure: String = ""
    @State private var isGenerating: Bool = false

    var body: some View {
        VStack {
            Button("Select Folder") {
                selectFolder()
            }
            .buttonStyle(.bordered)
            
            Button("Generate Tree") {
                if let url = folderURL {
                    isGenerating = true
                    generateTree(for: url)
                    isGenerating = false
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(folderURL == nil || isGenerating)
            
            Button("Copy to Clipboard") {
                copyToClipboard(text: treeStructure)
            }
            .buttonStyle(.bordered)
            .disabled(treeStructure.isEmpty)
            
            ScrollView {
                Text(treeStructure)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }

    func selectFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        
        if panel.runModal() == .OK {
            folderURL = panel.url
            // Create a security-scoped bookmark
            if let bookmarkData = try? folderURL?.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                UserDefaults.standard.set(bookmarkData, forKey: "selectedFolderBookmark")
            }
        }
    }

    func generateTree(for url: URL) {
        var treeString = ""
        
        // Start accessing the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            treeStructure = "Failed to access the folder."
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        func traverse(_ url: URL, level: Int) {
            let fileManager = FileManager.default
            guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else { return }
            
            for case let fileURL as URL in enumerator {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .nameKey]),
                      let isDirectory = resourceValues.isDirectory,
                      let name = resourceValues.name else {
                    continue
                }
                
                if name == "node_modules" || name == ".git" {
                    enumerator.skipDescendants()
                    continue
                }
                
                let indent = String(repeating: "    ", count: level)
                treeString += "\(indent)\(isDirectory ? "|-- " : "|   ")\(name)\n"
                
                if isDirectory {
                    traverse(fileURL, level: level + 1)
                }
            }
        }
        
        traverse(url, level: 0)
        treeStructure = treeString
    }

    func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
