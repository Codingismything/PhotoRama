//
//  FlickrAPI.swift
//  PhotoRama
//
//  Created by Milos Tomic on 29/06/2021.
//

import Foundation

enum EndPoint: String {
    case interestingPhotos = "flickr.interestingness.getList"
}

struct FlickrAPI {
    
    private static let baseUrlString = "https://api.flickr.com/services/rest"
    private static let apiKey = "a6d819499131071f158fd740860a5a88"
    
    private static func flickrUrl(endPoint: EndPoint, parameters:[String : String]?) -> URL {
        
        var components = URLComponents(string: baseUrlString)!
        var queryItems = [URLQueryItem]()
        
        let baseParams = [
            
            "method": endPoint.rawValue,
            "format": "json",
            "nojsoncallback": "1",
            "api_key": apiKey
            
        ]
        
        for (key, value) in baseParams {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        
        if let additionalParams = parameters {
            for (key, value) in additionalParams {
                let item = URLQueryItem(name: key, value: value)
                queryItems.append(item)
            }
        }
        
        components.queryItems = queryItems
        
        return components.url!
    }
    
    static var interestingPhotosURL: URL {
        return flickrUrl(endPoint: .interestingPhotos, parameters: ["extras": "url_z, date_taken"])
    }
    
    struct FlickrResponse: Codable {
        let photosInfo: FlickrPhotosResponse
        
        enum CodingKeys: String, CodingKey {
            case photosInfo = "photos"
        }
    }
    
    struct FlickrPhotosResponse: Codable {
        let photos: [FlickrPhoto]
        
        enum CodingKeys:String , CodingKey {
            case photos = "photo"
        }
    }
    
    static func photos(fromjson data: Data) -> Result<[FlickrPhoto],Error> {
        
        do {
            let decoder = JSONDecoder()
            
            //providing custom date decoding strategy for json decoder
            
            let dateformatter = DateFormatter()
            dateformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateformatter.locale = Locale(identifier: "en_US_POSIX")
            dateformatter.timeZone = TimeZone(secondsFromGMT: 0)
            decoder.dateDecodingStrategy = .formatted(dateformatter)
            
            
            let flickrResponse = try decoder.decode(FlickrResponse.self, from: data)
            //            return .success(flickrResponse.photosInfo.photos)
            let photos = flickrResponse.photosInfo.photos.filter { $0.remoteURL != nil}
            
            return .success(photos)
        } catch  {
            return .failure(error)
        }
    }
    
    
    
}
