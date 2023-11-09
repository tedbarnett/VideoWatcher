//
//  GoogleDriveAPI.swift
//  VideoWatcher
//
//  Created by MyMac on 08/11/23.
//

import Foundation
import GoogleAPIClientForREST_Drive

class GoogleDriveAPI {
    private let service: GTLRDriveService
    
    init(service: GTLRDriveService) {
        self.service = service
    }
    
    public func search(_ name: String, onCompleted: @escaping (GTLRDrive_File?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 1
        query.q = "name contains '\(name)'"
        self.service.executeQuery(query) { (ticket, results, error) in
            onCompleted((results as? GTLRDrive_FileList)?.files?.first, error)
        }
    }
    
    public func listFiles(_ folderID: String, pageToken: String? = nil, onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 20

        let root = "(mimeType = 'application/vnd.google-apps.folder' or mimeType = 'video/mp4' or mimeType = 'video/x-m4v' or mimeType = 'video/quicktime' or mimeType = 'video/m4v' or mimeType = 'video/mov') and '\(folderID)' in parents and trashed=false"
        //let root = "(mimeType = 'application/vnd.google-apps.folder' or mimeType = 'video/mp4' or mimeType = 'video/x-m4v' or mimeType = 'video/quicktime' or mimeType = 'image/png' or mimeType = 'image/jpeg') and '\(folderID)' in parents and trashed=false"
        query.q = root
        query.fields = "files(id,name,mimeType,modifiedTime,createdTime,fileExtension,size,parents,kind),nextPageToken"
        query.orderBy = "name"
        
        if let pageToken = pageToken {
            query.pageToken = pageToken
        }
        
        self.service.executeQuery(query) { (ticket, result, error) in
            onCompleted(result as? GTLRDrive_FileList, error)
        }
    }
    
    public func download(_ fileItem: GTLRDrive_File, onCompleted: @escaping (Data?, Error?) -> ()) {
        guard let fileID = fileItem.identifier else {
            return onCompleted(nil, nil)
        }
        
        self.service.executeQuery(GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileID)) { (ticket, file, error) in
            guard let data = (file as? GTLRDataObject)?.data else {
                return onCompleted(nil, nil)
            }
            
            onCompleted(data, nil)
        }
    }
    
    private func upload(_ folderID: String, fileName: String, data: Data, MIMEType: String, onCompleted: ((String?, Error?) -> ())?) {
        let file = GTLRDrive_File()
        file.name = fileName
        file.parents = [folderID]
        
        let params = GTLRUploadParameters(data: data, mimeType: MIMEType)
        params.shouldUploadWithSingleRequest = true
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: params)
        query.fields = "id"
        
        self.service.executeQuery(query, completionHandler: { (ticket, file, error) in
            onCompleted?((file as? GTLRDrive_File)?.identifier, error)
        })
    }
    
    public func delete(_ fileItem: GTLRDrive_File, onCompleted: @escaping ((Error?) -> ())) {
        guard let fileID = fileItem.identifier else {
            return onCompleted(nil)
        }
        
        self.service.executeQuery(GTLRDriveQuery_FilesDelete.query(withFileId: fileID)) { (ticket, nilFile, error) in
            onCompleted(error)
        }
    }
}
