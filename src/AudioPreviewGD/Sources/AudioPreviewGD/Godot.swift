import SwiftGodot

let registeredTypes: [Wrapped.Type] = [
    AudioPreview.self,
    AudioPreviewGenerator.self
]

#initSwiftExtension(cdecl: "swift_entry_point", types: registeredTypes)