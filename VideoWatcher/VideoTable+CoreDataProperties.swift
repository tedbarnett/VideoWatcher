//
//  VideoTable+CoreDataProperties.swift
//  VideoWatcher
//
//  Created by MyMac on 04/08/23.
//
//

import Foundation
import CoreData

extension VideoTable {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VideoTable> {
        return NSFetchRequest<VideoTable>(entityName: "VideoTable")
    }

    @NSManaged public var videoURL: String?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var is_Deleted: Bool

}

extension VideoTable : Identifiable {

}
