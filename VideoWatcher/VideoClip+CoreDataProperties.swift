//
//  VideoClip+CoreDataProperties.swift
//  VideoWatcher
//
//  Created by MyMac on 16/08/23.
//
//

import Foundation
import CoreData


extension VideoClip {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VideoClip> {
        return NSFetchRequest<VideoClip>(entityName: "VideoClip")
    }

    @NSManaged public var clipURL: String?
    @NSManaged public var is_Deleted: Bool
    @NSManaged public var thumbnailURL: String?
    @NSManaged public var startSeconds: String?
    @NSManaged public var video: VideoTable?

}

extension VideoClip : Identifiable {

}
