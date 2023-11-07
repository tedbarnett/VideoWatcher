//
//  VideoTable+CoreDataProperties.swift
//  VideoWatcher
//
//  Created by MyMac on 07/11/23.
//
//

import Foundation
import CoreData


extension VideoTable {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VideoTable> {
        return NSFetchRequest<VideoTable>(entityName: "VideoTable")
    }

    @NSManaged public var is_Deleted: Bool
    @NSManaged public var isFavorite: Bool
    @NSManaged public var thumbnailURL: String?
    @NSManaged public var videoURL: String?
    @NSManaged public var isBlank: Bool
    @NSManaged public var clips: NSSet?

}

// MARK: Generated accessors for clips
extension VideoTable {

    @objc(addClipsObject:)
    @NSManaged public func addToClips(_ value: VideoClip)

    @objc(removeClipsObject:)
    @NSManaged public func removeFromClips(_ value: VideoClip)

    @objc(addClips:)
    @NSManaged public func addToClips(_ values: NSSet)

    @objc(removeClips:)
    @NSManaged public func removeFromClips(_ values: NSSet)

}

extension VideoTable : Identifiable {

}
