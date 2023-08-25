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

    // MARK: - CRUD Functions for videos
    func isVideoExists(videoURL: String) -> Bool {
        let fetchRequest: NSFetchRequest<VideoTable> = VideoTable.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "videoURL == %@", videoURL)

        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking video URL existence: \(error)")
            return false
        }
    }
    
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
    
    func getRandomVideos(count: Int) -> [VideoTable] {
        let fetchRequest: NSFetchRequest<VideoTable> = VideoTable.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "is_Deleted == false")
        
        do {
            let videos = try context.fetch(fetchRequest)
            
            guard !videos.isEmpty else {
                return []
            }
            
            // Shuffle the videos and take the first 'count' videos
            let shuffledVideos = videos.shuffled()
            let randomVideos = shuffledVideos.prefix(count)
            
            return Array(randomVideos)
            
        } catch {
            print("Error fetching random videos: \(error)")
            return []
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

    func updateIsDeleted(videoURL: String) {
        let fetchRequest: NSFetchRequest<VideoTable> = VideoTable.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "videoURL == %@", videoURL)

        do {
            if let video = try context.fetch(fetchRequest).first {
                video.is_Deleted = true
                try context.save()
            }
        } catch {
            print("Error updating isDeleted: \(error)")
        }
    }
    
    func renameVideo(videoURL: String, newVideoURL: String) {
        let fetchRequest: NSFetchRequest<VideoTable> = VideoTable.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "videoURL == %@", videoURL)

        do {
            if let video = try context.fetch(fetchRequest).first {
                video.videoURL = newVideoURL
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
        //fetchRequest.predicate = NSPredicate(format: "is_Deleted == false")
        
        do {
            let videos = try context.fetch(fetchRequest)
            return videos
        } catch {
            print("Error fetching videos: \(error)")
            return []
        }
    }
    
    func getAllVideosExceptDeleted() -> [VideoTable] {
        let fetchRequest: NSFetchRequest<VideoTable> = VideoTable.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "is_Deleted == false")
        
        do {
            let videos = try context.fetch(fetchRequest)
            return videos
        } catch {
            print("Error fetching videos: \(error)")
            return []
        }
    }
    
    func getVideoFrom(videoURL: String) -> VideoTable? {
        let fetchRequest: NSFetchRequest<VideoTable> = VideoTable.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "videoURL == %@", videoURL)
        
        do {
            let videos = try context.fetch(fetchRequest)
            if let video = videos.first {
                print("Fetched video: \(video)")
                return video
            } else {
                print("No matching video found.")
                return nil
            }
        } catch {
            print("Error fetching video: \(error)")
            return nil
        }
    }
    
    func getAllFavoriteVideos() -> [VideoTable] {
        let fetchRequest: NSFetchRequest<VideoTable> = VideoTable.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isFavorite == true AND is_Deleted == false")
        
        do {
            let videos = try context.fetch(fetchRequest)
            return videos
        } catch {
            print("Error fetching videos: \(error)")
            return []
        }
    }
    
    func saveThumbnailOfVideo(videoURL: String, thumbULR: String) {
        let fetchRequest: NSFetchRequest<VideoTable> = VideoTable.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "videoURL == %@", videoURL)

        do {
            if let video = try context.fetch(fetchRequest).first {
                video.thumbnailURL = thumbULR
                try context.save()
            }
        } catch {
            print("Error updating isFavorite: \(error)")
        }
    }
    
    func getDeletedVideos() -> [VideoTable] {
        let fetchRequest: NSFetchRequest<VideoTable> = VideoTable.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "is_Deleted == true")
        do {
            let videos = try context.fetch(fetchRequest)
            return videos
        } catch {
            print("Error fetching videos: \(error)")
            return []
        }
    }
    
    // MARK: - CRUD Functions for clips
    func saveClip(clipURL: String, thumbnailURL: String, videoAsset: VideoTable, startSeconds: String) {
        let clip = VideoClip(context: context)
        clip.clipURL = clipURL
        clip.thumbnailURL = thumbnailURL
        clip.video = videoAsset
        clip.is_Deleted = false
        clip.startSeconds = startSeconds
        do {
            try context.save()
        } catch {
            print("Error saving clip: \(error)")
        }
    }
    
    func getAllClips() -> [VideoClip] {
        let fetchRequest: NSFetchRequest<VideoClip> = VideoClip.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "is_Deleted == false")
        
        do {
            let videos = try context.fetch(fetchRequest)
            return videos
        } catch {
            print("Error fetching clips: \(error)")
            return []
        }
    }
    
    func deleteClip(clipURL: String) {
        let fetchRequest: NSFetchRequest<VideoClip> = VideoClip.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "clipURL == %@", clipURL)

        do {
            if let clip = try context.fetch(fetchRequest).first {
                context.delete(clip)
                try context.save()
            }
        } catch {
            print("Error deleting clip: \(error)")
        }
    }
    
    func updateClipIsDeleted(clipURL: String) {
        let fetchRequest: NSFetchRequest<VideoClip> = VideoClip.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "clipURL == %@", clipURL)

        do {
            if let clip = try context.fetch(fetchRequest).first {
                clip.is_Deleted = true
                try context.save()
            }
        } catch {
            print("Error updating isDeleted: \(error)")
        }
    }
    
    func renameClip(clipURL: String, newClipURL: String) {
        let fetchRequest: NSFetchRequest<VideoClip> = VideoClip.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "clipURL == %@", clipURL)

        do {
            if let video = try context.fetch(fetchRequest).first {
                video.clipURL = newClipURL
                try context.save()
            }
        } catch {
            print("Error renaming clip: \(error)")
        }
    }
    
    func generateCSVFromVideoClips() -> URL? {
        let fetchRequest: NSFetchRequest<VideoClip> = VideoClip.fetchRequest()
        
        do {
            let videoClips = try context.fetch(fetchRequest)
            
            // Create a string for CSV content
            var csvString = "File Name,Start (secs),Clip Title\n"
            
            for videoClip in videoClips {
                if let clipURL = videoClip.clipURL,
                   let startSeconds = videoClip.startSeconds {
                    
                    csvString += "\"\(videoClip.video?.videoURL ?? "")\",\"\(startSeconds)\",\"\(self.removeFileExtension(from: clipURL))\"\n"
                }
            }
            
            // Create a temporary file to hold the CSV content
            let tempDirectoryURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("Favorites(from VideoWatcher).csv")
            
            // Write the CSV content to the temporary file
            do {
                try csvString.write(to: tempDirectoryURL, atomically: true, encoding: .utf8)
                return tempDirectoryURL
                
            } catch {
                print("Error writing CSV content to temporary file: \(error)")
                return nil
            }
            
        } catch {
            print("Error fetching VideoClip records: \(error)")
            return nil
        }
    }
    
    func removeFileExtension(from filename: String) -> String {
        if let dotIndex = filename.lastIndex(of: ".") {
            return String(filename[..<dotIndex])
        }
        return filename
    }
    
    func getDeletedClips() -> [VideoClip] {
        let fetchRequest: NSFetchRequest<VideoClip> = VideoClip.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "is_Deleted == true")
        do {
            let videos = try context.fetch(fetchRequest)
            return videos
        } catch {
            print("Error fetching clips: \(error)")
            return []
        }
    }
}
