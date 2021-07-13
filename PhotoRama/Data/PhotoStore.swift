//
//  PhotoStore.swift
//  PhotoRama
//
//  Created by Milos Tomic on 29/06/2021.
//

import UIKit
import CoreData

enum PhotoError: Error {
    case imageCreationError
    case missingImageURL
}

class PhotoStore {
    
    let imageStore = ImageStore()
    
    let persistentContainer: NSPersistentContainer = {
       let container = NSPersistentContainer(name: "PhotoRama")
        container.loadPersistentStores { (description, error) in
            if let error = error {
                print("Error setting up Core Data")
            }
        }
        return container
    }()
    
    
    
    
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    //making url request and datatask to fetch json data interesting photos
    func fetchInterestingPhotos(completion: @escaping (Result<[Photo], Error>) -> Void) {
        
        let url = FlickrAPI.interestingPhotosURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) in
            
//            if let jsonData = data {
//                if let jsonString = String(data: jsonData, encoding: .utf8) {
//                    print(jsonString)
//                }
//            } else if let errorRequest = error {
//                print("Error fetching interesting photos: \(errorRequest)")
//            } else {
//                print("Unexpected error with the request")
//            }
            //saving photos on succcessful catch
            
            var result = self.procesPhotosrequest(data: data, error: error)
            
            if case .success = result {
                do {
                    try self.persistentContainer.viewContext.save()
                } catch {
                    result = .failure(error)
                }
            }
            OperationQueue.main.addOperation {
                completion(result)
            }
            
        }
        
        
        task.resume()
        
    }
    
    //encoding json into object model by parsing into FlickrResponse type
    
    private func procesPhotosrequest(data: Data?,error:Error?) -> Result<[Photo], Error> {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        let context = persistentContainer.viewContext
        
        switch FlickrAPI.photos(fromjson: jsonData) {
        case let .success(flickrPhotos):
            // returning Photo objecct so we can put it into context and save it to core data later
            let photos = flickrPhotos.map { flickrPhoto -> Photo in
                var photo: Photo!
                context.performAndWait {
                    photo = Photo(context: context)
                    photo.title = flickrPhoto.title
                    photo.photoID = flickrPhoto.photoID
                    photo.remoteURL = flickrPhoto.remoteURL
                    photo.dateTaken = flickrPhoto.dateTaken
                }
                return photo
            }
            return .success(photos)
        case let .failure(error):
        return .failure(error)
        }
        
    }
    
    //fetching image using URL from json parsing to Photo object
    
    func fetchImage(for photo: Photo, completion: @escaping (Result<UIImage, Error>) -> Void) {
        
        
        guard let photoKey = photo.photoID else {
            preconditionFailure("Photo does not have photoID")
        }
       
        if let image = imageStore.image(forKey: photoKey) {
            OperationQueue.main.addOperation {
                completion(.success(image))
            }
            
            return
        }
        
        guard let photoURL = photo.remoteURL else {
            completion(.failure(PhotoError.missingImageURL))
            return
        }
        
        let request = URLRequest(url: photoURL)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            let result = self.processImageRequest(data: data, errror: error)
            
            //checking if fetching and processing image have been successful and only in that case saving it on the disk as it is not in the cache memory or on the disk already as we checked with image function previously.
            if case let .success(image) = result {
                self.imageStore.setImage(image, forKey: photoKey)
            }
            OperationQueue.main.addOperation {
                completion(result)
            }
            
        }
        
        task.resume()
    }
    
    
    
    //implementing method that processes data from the web request into an image
    
    func processImageRequest(data: Data?, errror: Error?) -> Result<UIImage, Error> {
        guard let imageData = data,
        // making an image object out of the image data that is fetched through dataTask
        let image = UIImage(data: imageData)
              else {
            
            //couldn't create an image
            if data == nil {
                return .failure(errror!)
            } else {
                return .failure(PhotoError.imageCreationError)
            }
        
        }
      
        return .success(image)
    }
    
    
    
    // Implementing method to fetch all photos from the disk
    
    func fetchAllPhotos(completion: @escaping (Result<[Photo], Error>) -> Void) {
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortByDatTaken = NSSortDescriptor(key: #keyPath(Photo.dateTaken), ascending: true)
        
        request.sortDescriptors = [sortByDatTaken]
        
        let viewContext = persistentContainer.viewContext
        
        viewContext.perform {
            do {
                let allPhotos =  try viewContext.fetch(request)
                completion(.success(allPhotos))
            } catch  {
                completion(.failure(error))
            }
        }
    }
}
