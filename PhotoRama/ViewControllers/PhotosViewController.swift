//
//  ViewController.swift
//  PhotoRama
//
//  Created by Milos Tomic on 29/06/2021.
//

import UIKit

class PhotosViewController: UIViewController,UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var collectionView: UICollectionView!
    
    var store: PhotoStore!
    
    let photoDataSource = PhotoDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = photoDataSource
        collectionView.delegate = self
        
        store.fetchInterestingPhotos { (photosResult) in
            
//            switch photosResult {
//            case let .success(photos):
//                print("Sucessfully found \(photos.count) photos")
//                //updating imageview with the first photo from the collection
////                if let firstPhoto = photos.first {
////                    self.updateImageView(for: firstPhoto)
////                }
//            //updating datasource with photos data
//                self.photoDataSource.photos = photos
//            case let .failure(error):
//                print("Eerror fetching interesting photos \(error)")
//                self.photoDataSource.photos.removeAll()
//            }
//
//            self.collectionView.reloadSections(IndexSet(integer: 0))
            
            self.updateDataSource()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    
        
        func collectionView(_ collectionView: UICollectionView,
                              layout collectionViewLayout: UICollectionViewLayout,
                              sizeForItemAt indexPath: IndexPath) -> CGSize {

            let screenwidth = UIScreen.main.bounds.width
            let cellwidth = screenwidth/4.0

            let size  = CGSize(width: cellwidth, height: cellwidth)

            return size
        }
    }
         
    
    //implementing delegate method to download images when item in the collection becomes visible on the screen.
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let photo = self.photoDataSource.photos[indexPath.row]
        
        //downloading image data which could take time
        
        store.fetchImage(for: photo) { (result) in
            
            //indexPath for the photo might have changed between the time the request started and finished, so we need to find the most recent indexPath
            
            guard let photoIndex = self.photoDataSource.photos.firstIndex(of:photo),
                  case let .success(image) = result else {
                return
            }
            
            let photoIndexPath = IndexPath(item: photoIndex, section: 0)
            
            //when the request finishes find the current cell for this photo
            if let cell = self.collectionView.cellForItem(at: photoIndexPath) as? PhotoCollectionViewCell {
                
                cell.update(displaying: image)
            }
           
        }
    }
    
    ///passing photo and the store to the PhotoInfoViewController
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showPhoto":
            if let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first {
                let photo = self.photoDataSource.photos[selectedIndexPath.row]
                
                let destinationVC = segue.destination as! PhotoInfoViewController
                destinationVC.photo = photo
                destinationVC.store = store
            }
        default:
            preconditionFailure("Unexpected segue identifier")
        }
    }
    
    
    private func updateDataSource() {
        store.fetchAllPhotos { (photoResult) in
            switch photoResult {
            case let .success(photos):
                self.photoDataSource.photos = photos
            case .failure:
                self.photoDataSource.photos.removeAll()
            }
            
            self.collectionView.reloadSections(IndexSet(integer: 0))
        }
    }
    
//    func updateImageView(for photo:Photo) {
//        store.fetchImage(for: photo) { (imageResult) in
//
//            switch imageResult {
//            case let .success(image):
//                self.imageView.image = image
//            case let .failure(error):
//                print("Error downloading image \(error)")
//            }
//        }
//    }


}

