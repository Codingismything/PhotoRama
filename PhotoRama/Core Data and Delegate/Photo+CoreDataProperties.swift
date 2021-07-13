//
//  Photo+CoreDataProperties.swift
//  PhotoRama
//
//  Created by Milos Tomic on 02/07/2021.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var dateTaken: Date?
    @NSManaged public var photoID: String?
    @NSManaged public var remoteURL: URL?
    @NSManaged public var title: String?

}

extension Photo : Identifiable {

}
