import CoreData
import CoreSpotlight
import MobileCoreServices

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    private var spotlightDelegate: NSCoreDataCoreSpotlightDelegate?
    
    init() {
        container = NSPersistentContainer(name: "BrainfulData")
        
        // Configure persistent store descriptions for Spotlight indexing
        if let description = container.persistentStoreDescriptions.first {
            // Enable history tracking (required for syncing with Spotlight)
            description.setOption(true as NSNumber,
                                 forKey: NSPersistentHistoryTrackingKey)
            
            // Enable Spotlight indexing
            description.setOption(true as NSNumber,
                                 forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        container.loadPersistentStores { [weak self] description, error in
            if let error = error {
                fatalError("Error loading Core Data stores: \(error)")
            }
            
            // Set up Spotlight indexing after store is loaded
            self?.setupSpotlightIndexing()
        }
    }
    
    private func setupSpotlightIndexing() {
        // Create the Core Spotlight delegate
        spotlightDelegate = NSCoreDataCoreSpotlightDelegate(forStoreWith: container.persistentStoreDescriptions.first!,
                                                           coordinator: container.persistentStoreCoordinator)
    }
}
