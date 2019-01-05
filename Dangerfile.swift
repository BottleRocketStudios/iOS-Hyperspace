import Danger

let danger = Danger()

//
//  Ensure CHANGELOG.md was modified for edits to source files.
//
let allSourceFiles = danger.git.modifiedFiles + danger.git.createdFiles

let changelogChanged = allSourceFiles.contains("CHANGELOG.md")
let sourceChanges = allSourceFiles.first(where: { $0.hasPrefix("Sources") })

if !changelogChanged && sourceChanges != nil {
    warn("No CHANGELOG entry added.")
}
