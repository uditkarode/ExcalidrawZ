//
//  PersistenceController.swift
//  ExcalidrawZ
//
//  Created by Dove Zachary on 2023/1/6.
//

import Foundation
import CoreData

struct PersistenceController {
    // A singleton for our entire app to use
    static let shared = PersistenceController()

    // Storage for Core Data
    let container: NSPersistentContainer

    // An initializer to load Core Data, optionally able
    // to use an in-memory store.
    init(inMemory: Bool = false) {
        // If you didn't name your model Main you'll need
        // to change this name below.
        container = NSPersistentContainer(name: "Model")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
        
        prepare()
    }
    
    func prepare() {
        Task {
            do {
                let fetch: NSFetchRequest<Group> = NSFetchRequest(entityName: "Group")
                fetch.predicate = NSPredicate(format: "name == 'default'")
                
                try await container.viewContext.perform {
                    let groups = try fetch.execute()
                    if groups.count == 0 {
                        // create the default group
                        let group = Group(context: container.viewContext)
                        group.id = UUID()
                        group.name = "default"
                        group.createdAt = .now
                    }
                }
                
            } catch {
                dump(error, name: "fetch groups failed")
            }
        }
    }
}

extension PersistenceController {
    func listGroups() throws -> [Group] {
        let fetchRequest = NSFetchRequest<Group>(entityName: "Group")
        fetchRequest.sortDescriptors = [.init(key: "createdAt", ascending: false)]
        return try container.viewContext.fetch(fetchRequest)
    }
    func listFiles(in group: Group) throws -> [File] {
        let fetchRequest = NSFetchRequest<File>(entityName: "File")
        fetchRequest.predicate = NSPredicate(format: "group == %@", group)
        fetchRequest.sortDescriptors = [.init(key: "updatedAt", ascending: false), .init(key: "createdAt", ascending: false)]
        return try container.viewContext.fetch(fetchRequest)
    }
    
    func createGroup(name: String) throws -> Group {
        let group = Group(context: container.viewContext)
        group.id = UUID()
        group.name = name
        group.createdAt = .now
        
        return group
    }
    
    func createFile(in group: Group) throws -> File {
        guard let templateURL = Bundle.main.url(forResource: "template", withExtension: "excalidraw") else { throw AppError.fileError(.notFound) }
        
        let file = File(context: container.viewContext)
        file.id = UUID()
        file.name = "Untitled"
        file.createdAt = .now
        file.group = group
        file.content = try Data(contentsOf: templateURL)
        return file
    }
    
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Show some error here
                dump(error)
            }
        }
    }
}

extension File {
    func updateElements(with elementsData: Data) throws {
        guard let data = self.content else { return }
        var obj = try JSONSerialization.jsonObject(with: data) as! [String : Any]
        let elements = try JSONSerialization.jsonObject(with: elementsData)
        obj["elements"] = elements
        self.content = try JSONSerialization.data(withJSONObject: obj)
        self.updatedAt = .now
    }
}

#if DEBUG
extension PersistenceController {
    // A test configuration for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)

        // Create 10 example programming languages.
//        for _ in 0..<10 {
//            let language = ProgrammingLanguage(context: controller.container.viewContext)
//            language.name = "Example Language 1"
//            language.creator = "A. Programmer"
//        }

        return controller
    }()
}
#endif
