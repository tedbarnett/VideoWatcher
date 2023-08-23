//
//  AppData.swift
//  VideoWatcher
//
//  Created by MyMac on 09/08/23.
//

import Foundation

class AppData {
    static let shared = AppData()
    
    var panel1IsMute = true
    var panel2IsMute = true
    var panel3IsMute = true
    var panel4IsMute = true
    var panel5IsMute = true
    var panel6IsMute = true
    
    var panel1PreviousVideos: [String] = []
    var panel1PreviousVideosIndex = -1
    var panel1PreviousVideosIndexCopy = -1
    //
    var panel2PreviousVideos: [String] = []
    var panel2PreviousVideosIndex = -1
    var panel2PreviousVideosIndexCopy = -1
    
    var panel3PreviousVideos: [String] = []
    var panel3PreviousVideosIndex = -1
    var panel3PreviousVideosIndexCopy = -1
    
    var panel4PreviousVideos: [String] = []
    var panel4PreviousVideosIndex = -1
    var panel4PreviousVideosIndexCopy = -1
    
    var panel5PreviousVideos: [String] = []
    var panel5PreviousVideosIndex = -1
    var panel5PreviousVideosIndexCopy = -1
    
    var panel6PreviousVideos: [String] = []
    var panel6PreviousVideosIndex = -1
    var panel6PreviousVideosIndexCopy = -1
}
