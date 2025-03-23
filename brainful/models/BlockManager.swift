import CoreData
import Foundation

class BlockManager {
    static let shared = BlockManager()
    private let viewContext = PersistenceController.shared.container.viewContext
    
    // Save blocks to Core Data
    func saveBlocks(_ blocks: [Block]) {
        print("⬇️ Attempting to save \(blocks.count) blocks to Core Data")
        
        for block in blocks {
            print("📦 Processing block: LUID=\(block.luid), Slug=\(block.slug)")
            
            // Updated entity name to BlockModel
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "BlockModel")
            fetchRequest.predicate = NSPredicate(format: "luid == %@", block.luid)
            
            do {
                let results = try viewContext.fetch(fetchRequest)
                print("🔍 Fetch request found \(results.count) existing blocks with LUID \(block.luid)")
                
                let blockEntity: NSManagedObject
                
                if let existingBlock = results.first {
                    // Update existing
                    print("🔄 Updating existing block: \(block.luid)")
                    blockEntity = existingBlock
                } else {
                    // Create new with updated entity name
                    print("➕ Creating new block: \(block.luid)")
                    let entity = NSEntityDescription.entity(forEntityName: "BlockModel", in: viewContext)!
                    blockEntity = NSManagedObject(entity: entity, insertInto: viewContext)
                    blockEntity.setValue(block.luid, forKey: "luid")
                }
                
                // Set properties
                print("📝 Setting properties for block \(block.luid)")
                blockEntity.setValue(block.slug, forKey: "slug")
                blockEntity.setValue(block.type, forKey: "type")
                blockEntity.setValue(block.pinned, forKey: "pinned")
                blockEntity.setValue(block.created_timestamp, forKey: "created_timestamp")
                blockEntity.setValue(block.last_edited, forKey: "last_edited")
                blockEntity.setValue(block.text, forKey: "text")
            } catch {
                print("❌ Error saving block \(block.luid): \(error)")
            }
        }
        
        // Save changes
        do {
            print("💾 Attempting to save Core Data context with \(blocks.count) blocks")
            try viewContext.save()
            print("✅ Successfully saved Core Data context")
            
            // Verify save by counting entities
            let countFetch = NSFetchRequest<NSNumber>(entityName: "BlockModel")
            countFetch.resultType = .countResultType
            let count = try viewContext.count(for: countFetch)
            print("📊 Total blocks in Core Data after save: \(count)")
        } catch {
            print("❌ Error saving context: \(error)")
        }
    }
    
    // Get all blocks from Core Data
    func getAllBlocks() -> [Block] {
        print("🔍 Attempting to retrieve all blocks from Core Data")
        
        // Updated entity name to BlockModel
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "BlockModel")
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            print("📋 Retrieved \(results.count) blocks from Core Data")
            
            if results.isEmpty {
                print("⚠️ No blocks found in Core Data!")
            } else {
                print("🔢 First few blocks: \(results.prefix(3).map { $0.value(forKey: "luid") as? String ?? "unknown" }.joined(separator: ", "))")
            }
            
            return results.map { blockEntity in
                let luid = blockEntity.value(forKey: "luid") as? String ?? ""
                let slug = blockEntity.value(forKey: "slug") as? String ?? ""
                print("🔄 Converting Core Data entity to Block: LUID=\(luid), Slug=\(slug)")
                
                return Block(
                    luid: luid,
                    slug: slug,
                    type: blockEntity.value(forKey: "type") as? String ?? "",
                    pinned: blockEntity.value(forKey: "pinned") as? Bool ?? false,
                    created_timestamp: blockEntity.value(forKey: "created_timestamp") as? Date,
                    last_edited: blockEntity.value(forKey: "last_edited") as? Date,
                    text: blockEntity.value(forKey: "text") as? String
                )
            }
        } catch {
            print("❌ Error fetching blocks: \(error)")
            return []
        }
    }
    
    // Get block by ID
    func getBlock(luid: String) -> Block? {
        print("🔍 Attempting to retrieve block with LUID: \(luid)")
        
        // Updated entity name to BlockModel
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "BlockModel")
        fetchRequest.predicate = NSPredicate(format: "luid == %@", luid)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            print("🔍 Fetch request found \(results.count) blocks with LUID \(luid)")
            
            if let blockEntity = results.first {
                print("✅ Found block with LUID \(luid)")
                return Block(
                    luid: blockEntity.value(forKey: "luid") as? String ?? "",
                    slug: blockEntity.value(forKey: "slug") as? String ?? "",
                    type: blockEntity.value(forKey: "type") as? String ?? "",
                    pinned: blockEntity.value(forKey: "pinned") as? Bool ?? false,
                    created_timestamp: blockEntity.value(forKey: "created_timestamp") as? Date,
                    last_edited: blockEntity.value(forKey: "last_edited") as? Date,
                    text: blockEntity.value(forKey: "text") as? String
                )
            } else {
                print("⚠️ No block found with LUID \(luid)")
            }
        } catch {
            print("❌ Error fetching block \(luid): \(error)")
        }
        
        return nil
    }
}
