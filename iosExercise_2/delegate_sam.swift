//
//  delegate_sam.swift
//  iosExercise_2
//
//  Created by 莊善傑 on 2024/6/14.
//

import Foundation

import MapKit


protocol popupViewStationListDelegate: AnyObject {
    func didSelectStation(_ matchingHotel: StationInfo)
    func didSelectStationWithStartBtn(_ matchingHotel: StationInfo)
    func didSelectStationWithEndBtn(_ matchingHotel: StationInfo)
}


