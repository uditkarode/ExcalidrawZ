//
//  FileListView.swift
//  ExcalidrawZ
//
//  Created by Dove Zachary on 2023/1/4.
//

import SwiftUI

struct FileListView: View {
    @EnvironmentObject var store: AppStore
    @FetchRequest var files: FetchedResults<File>
    
    init(group: Group?) {
        self._files = FetchRequest<File>(sortDescriptors: [SortDescriptor(\.updatedAt, order: .reverse),
                                                           SortDescriptor(\.createdAt, order: .reverse)],
                                   predicate: group != nil ? NSPredicate(format: "group == %@", group!) : NSPredicate(value: false))
    }
    
    private var selectedFile: Binding<File?> {
        store.binding(for: \.currentFile) {
            return .setCurrentFile($0)
        }
    }
    
    var body: some View {
        List(files, id: \.id, selection: selectedFile) { file in
            FileRowView(fileInfo: file)
        }
        .animation(.easeIn, value: files)
    }
}

struct FileListView_Previews: PreviewProvider {
    static var previews: some View {
        FileListView(group: nil)
    }
}
