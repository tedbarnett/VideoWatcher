//
//  CoreDataManager.swift
//  VideoWatcher
//
//  Created by MyMac on 04/08/23.
//

import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "VideoWatcher")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - CRUD Functions

    func saveVideo(videoURL: String) {
        let video = VideoTable(context: context)
        video.videoURL = videoURL
        video.isFavorite = false
        video.is_Deleted = false

        do {
            try context.save()
        } catch {
            print("Error saving video: \(error)")
        }
    }

    func updateIsFavorite(videoURL: String, isFavorite: Bool) {
        let fetchRequest: NSFetchRequest<VideoTable> = VideoTable.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "videoURL == %@", videoURL)

        do {
            if let video = try context.fetch(fetchRequest).first {
                video.isFavorite = isFavorite
                try context.save()
            }
        } catch {
            print("Error updating isFavorite: \(error)")
        }
    }

    func updateIsDeleted(videoURL: String, isDeleted: Bool) {
        let fetchRequest: NSFetchRequest<VideoTable> = VideoTable.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "videoURL == %@", videoURL)

        do {
            if let video = try context.fetch(fetchRequest).first {
                video.is_Deleted = isDeleted
                try context.save()
            }
        } catch {
            print("Error updating isDeleted: \(error)")
        }
    }

    func deleteVideo(videoURL: String) {
        let fetchRequest: NSFetchRequest<VideoTable> = VideoTable.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "videoURL == %@", videoURL)

        do {
            if let video = try context.fetch(fetchRequest).first {
                context.delete(video)
                try context.save()
            }
        } catch {
            print("Error deleting video: \(error)")
        }
    }
        
    func getAllVideos() -> [VideoTable] {
        let fetchRequest: NSFetchRequest<VideoTable> = VideoTable.fetchRequest()
        
        do {
            let videos = try context.fetch(fetchRequest)
            return videos
        } catch {
            print("Error fetching videos: \(error)")
            return []
        }
    }
    
    func getRandomVideos(count: Int) -> [String] {
            let fetchRequest: NSFetchRequest<VideoTable> = VideoTable.fetchRequest()
            
            do {
                let videos = try context.fetch(fetchRequest)
                
                guard !videos.isEmpty else {
                    return []
                }
                
                // Shuffle the videos and take the first 'count' videos
                let shuffledVideos = videos.shuffled()
                let randomVideos = shuffledVideos.prefix(count)
                
                return randomVideos.compactMap { $0.videoURL }
            } catch {
                print("Error fetching random videos: \(error)")
                return []
            }
        }
}
