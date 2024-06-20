//
//  ViewController.swift
//  iosExercise_2
//
//  Created by 莊善傑 on 2024/6/13.
//

import UIKit
import MapKit
import Toast

struct Station: Codable {
    let StationID: String
    let StationAddress: String
    let StationName: StationName
    let StationPosition: StationPosition
}

struct StationName: Codable {
    let Zh_tw: String
}

struct StationPosition: Codable {
    let PositionLon: Double
    let PositionLat: Double
}

struct StationInfo {
    let stationID : String
    let addr: String
    let name: String
    let lon: Double
    let lat: Double
}

struct DailyTimetable: Decodable {
    let DailyTrainInfo: TrainInfo
    let OriginStopTime: StopTime
    let DestinationStopTime: StopTime
}

struct TrainInfo: Decodable {
    let TrainNo: String
    let Direction: Int
}

struct StopTime: Decodable {
    let ArrivalTime: String?
    let DepartureTime: String?
}

struct DailyTime {
    let TrainNo : String
    let Direction: Int
    let OriginDepartureTime : String
    let DestinationArrivalTime : String
}


let clientId = "t109362507-f17390c4-d25b-41c4"
let clientSecret = "feb97d2b-7598-451d-be92-365237e986df"
let authUrlString = "https://tdx.transportdata.tw/auth/realms/TDXConnect/protocol/openid-connect/token"
let apiUrlString = "https://tdx.transportdata.tw/api/basic/v2/Rail/THSR/Station?%24top=30&%24format=JSON"

func getAccessToken(completion: @escaping (String?) -> Void) {
        guard let url = URL(string: authUrlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyData = "grant_type=client_credentials&client_id=\(clientId)&client_secret=\(clientSecret)"
        request.httpBody = bodyData.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("獲取令牌失敗: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("獲取令牌失敗: 無數據返回")
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let accessToken = json["access_token"] as? String {
                    completion(accessToken)
                } else {
                    print("獲取令牌失敗: 無法解析JSON")
                    completion(nil)
                }
            } catch {
                print("獲取令牌失敗: \(error.localizedDescription)")
                completion(nil)
            }
        }
        task.resume()
    }

class ViewController: UIViewController {
    
    var stationInfos: [StationInfo] = []
    var dailyTimeInfos: [DailyTime] = []
    var selectedAnnotation: MKAnnotation?

    @IBOutlet weak var startStationBtn: UIButton!
    @IBOutlet weak var endStationBtn: UIButton!
    @IBOutlet weak var exchangeStationBtn: UIButton!
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()

        initStation()
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        
        mapView.delegate = self
        
        getAccessToken { accessToken in
            if let token = accessToken {
                self.getStationData(accessToken: token)
            }}
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //重置Annotation狀態
        deselectAnnotation()
    }
    
        // 獲取車站資料
        func getStationData(accessToken: String) {
            guard let url = URL(string: apiUrlString) else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("獲取車站資料失敗: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    print("獲取車站資料失敗: 無數據返回")
                    return
                }

                do {
                    let stations = try JSONDecoder().decode([Station].self, from: data)
                    for station in stations {
                        let stationID = station.StationID
                        let addr = station.StationAddress
                        let name = station.StationName.Zh_tw
                        let lon = station.StationPosition.PositionLon
                        let lat = station.StationPosition.PositionLat
                        
                        let stationInfo = StationInfo(stationID:stationID,addr: addr, name: name, lon: lon, lat: lat)
                        self.stationInfos.append(stationInfo)
                    }
                    DispatchQueue.main.async {
                        self.addAnnotations()
                    }
                } catch {
                    print("解析車站資料失敗: \(error.localizedDescription)")
                }
            }
            task.resume()
        }
    
    // 構造 DailyTimetable 的 API URL
    func buildDailyTimetableURL(from origin: String, to destination: String, date: String) -> URL? {
        let apiUrlString = "https://tdx.transportdata.tw/api/basic/v2/Rail/THSR/DailyTimetable/OD/\(origin)/to/\(destination)/\(date)?%24top=60&%24format=JSON"
        return URL(string: apiUrlString)
    }
    
    func getDailyTimetable(origin: String, destination: String, date: String, accessToken: String, completion: @escaping ([DailyTime]) -> Void) {
     
        guard let url = buildDailyTimetableURL(from: origin, to: destination, date: date) else {
            print("URL 構建失敗")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("獲取每日時刻表資料失敗: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("獲取每日時刻表資料失敗: 無數據返回")
                return
            }
            do {
                let dailyTimetables = try JSONDecoder().decode([DailyTimetable].self, from: data)
                for timetable in dailyTimetables {
                    
                                    let trainNo = timetable.DailyTrainInfo.TrainNo
                                    let direction = timetable.DailyTrainInfo.Direction
                                    let originDepartureTime = timetable.OriginStopTime.DepartureTime ?? "N/A"
                                    let destinationArrivalTime = timetable.DestinationStopTime.ArrivalTime ?? "N/A"

                                    let dailyTimeInfo = DailyTime(TrainNo: trainNo, Direction: direction, OriginDepartureTime: originDepartureTime, DestinationArrivalTime: destinationArrivalTime)
  
                                    self.dailyTimeInfos.append(dailyTimeInfo)
                                }
                completion(self.dailyTimeInfos)
            } catch {
                print("解析每日時刻表資料失敗: \(error.localizedDescription)")
            }


        }
        task.resume()
    }


    func addAnnotations() {
        for station in stationInfos {
            setAnnotation(lat: station.lat, lon: station.lon, name: station.name ,addr: station.addr)
        }
    }
    
    func setAnnotation(lat: Double, lon: Double, name: String, addr: String) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        annotation.title = "\(name)高鐵站"
        annotation.subtitle = addr
        mapView.addAnnotation(annotation)
    }
    
    func deselectAnnotation() {
        if let annotation = selectedAnnotation {
            mapView.deselectAnnotation(annotation, animated: true)
        }
    }
    
    func initStation() {
        startStationBtn.setTitle("起始站點", for: .normal)
        startStationBtn.setTitleColor(.gray, for: .normal)
        endStationBtn.setTitle("終點站點", for: .normal)
        endStationBtn.setTitleColor(.gray, for: .normal)
    }
    
    func getStationID(byName name: String, from stations: [StationInfo]) -> String? {
        for station in stations {
            if station.name == name {
                return station.stationID
            }
        }
        return nil
    }
    
    func removeSubstring(_ originalString: String) -> String {
        if let range = originalString.range(of: "高鐵站") {
            var modifiedString = originalString
            modifiedString.removeSubrange(range)
            return modifiedString.trimmingCharacters(in: .whitespaces)
        }
        return originalString
    }

    @IBAction func startButtonTapped(_ sender: UIButton) {
        let PopupView = popupViewStationList()
        PopupView.stationInfos = self.stationInfos
        PopupView.state = 1
        PopupView.delegate = self
        PopupView.appear(sender: self)
    }
    
    @IBAction func endButtonTapped(_ sender: UIButton) {
        let PopupView = popupViewStationList()
        PopupView.stationInfos = self.stationInfos
        PopupView.state = 2
        PopupView.delegate = self
        PopupView.appear(sender: self)
    }

    @IBAction func swapButtonTapped(_ sender: UIButton) {
        let startTitle = startStationBtn.title(for: .normal)
        let endTitle = endStationBtn.title(for: .normal)
        
        if startTitle != "起始站點" && endTitle != "終點站點" {
            startStationBtn.setTitle(endTitle, for: .normal)
            endStationBtn.setTitle(startTitle, for: .normal)
        }
    }
    
    @IBAction func stationSearchBtn(_ sender: UIButton) {
        let PopupView = popupViewStationList()
        PopupView.stationInfos = self.stationInfos
        PopupView.delegate = self
        PopupView.appear(sender: self)
    }
    
    
    @IBAction func routePlanningBtn(_ sender: UIButton) {
        let startTitle = startStationBtn.title(for: .normal)
        let endTitle = endStationBtn.title(for: .normal)
        
        if startTitle == "起始站點" || endTitle == "終點站點" {
            self.view.makeToast("起點或終點未輸入地點")
        } else if startTitle == endTitle {
            self.view.makeToast("起點與終點相同請修改")
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let currentDate = Date()
            let formattedDate = dateFormatter.string(from: currentDate)
            
            guard let origin = getStationID(byName: removeSubstring(startStationBtn.titleLabel!.text!), from: stationInfos) else { return }
            guard let destination = getStationID(byName: removeSubstring(endStationBtn.titleLabel!.text!), from: stationInfos) else { return }

            getAccessToken { accessToken in
                if let token = accessToken {
                    self.dailyTimeInfos.removeAll()
                    self.getDailyTimetable(origin: origin, destination: destination, date: formattedDate, accessToken: token) { dailyTimeInfos in
                        DispatchQueue.main.async {
                            if let routePlanningVC = self.storyboard?.instantiateViewController(withIdentifier: "RoutePlanningViewController") as? RoutePlanningViewController {
                                routePlanningVC.dailyTimeInfos = dailyTimeInfos
                                routePlanningVC.originStation = self.startStationBtn.titleLabel!.text!
                                routePlanningVC.destinationStation = self.endStationBtn.titleLabel!.text!
                                self.navigationController?.pushViewController(routePlanningVC, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func showUserLocationBtn(_ sender: UIButton) {
        mapView.setCenter(mapView.userLocation.coordinate, animated: true)
        mapView.setRegion(MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 100, longitudinalMeters: 100), animated: true)
    }
}


extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        selectedAnnotation = view.annotation
        
        let controller = UIAlertController(title: view.annotation?.title!, message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(
          title: "取消",
          style: .cancel,
          handler: { _ in
              self.deselectAnnotation()
          })
        controller.addAction(cancelAction)
        
        let setStartingPointAction = UIAlertAction(
          title: "設定成起點",
          style: .default,
          handler: { _ in
              self.deselectAnnotation()
              if let annotationTitle = view.annotation?.title {
                  self.startStationBtn.setTitle("\(annotationTitle!)", for: .normal)
                  self.startStationBtn.setTitleColor(.black, for: .normal)
              }
          })
        controller.addAction(setStartingPointAction)
        
        let setEndPointAction = UIAlertAction(
          title: "設定成終點",
          style: .default,
          handler: { _ in
              self.deselectAnnotation()
              if let annotationTitle = view.annotation?.title {
                  self.endStationBtn.setTitle("\(annotationTitle!)", for: .normal)
                  self.endStationBtn.setTitleColor(.black, for: .normal)
              }
          })
        controller.addAction(setEndPointAction)
        
        self.present(controller,animated: true,completion: nil)
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if view.annotation === selectedAnnotation {
            selectedAnnotation = nil
        }
    }
}

extension ViewController: popupViewStationListDelegate {
    
    func didSelectStation(_ matchingHotel: StationInfo) {
        let searchAnnotation = MKPointAnnotation()
        searchAnnotation.coordinate = CLLocationCoordinate2D(latitude: matchingHotel.lat, longitude: matchingHotel.lon)
        mapView.setCenter(searchAnnotation.coordinate, animated: true)
        mapView.setRegion(MKCoordinateRegion(center: searchAnnotation.coordinate, latitudinalMeters: 100, longitudinalMeters: 100), animated: true)
    }
    
    func didSelectStationWithStartBtn(_ matchingHotel: StationInfo){
        let searchAnnotation = MKPointAnnotation()
        startStationBtn.setTitle("\(matchingHotel.name)高鐵站", for: .normal)
        startStationBtn.setTitleColor(.black, for: .normal)
        searchAnnotation.coordinate = CLLocationCoordinate2D(latitude: matchingHotel.lat, longitude: matchingHotel.lon)
        mapView.setCenter(searchAnnotation.coordinate, animated: true)
        mapView.setRegion(MKCoordinateRegion(center: searchAnnotation.coordinate, latitudinalMeters: 100, longitudinalMeters: 100), animated: true)
    }
    
    func didSelectStationWithEndBtn(_ matchingHotel: StationInfo){
        let searchAnnotation = MKPointAnnotation()
        endStationBtn.setTitle("\(matchingHotel.name)高鐵站", for: .normal)
        endStationBtn.setTitleColor(.black, for: .normal)
        searchAnnotation.coordinate = CLLocationCoordinate2D(latitude: matchingHotel.lat, longitude: matchingHotel.lon)
        mapView.setCenter(searchAnnotation.coordinate, animated: true)
        mapView.setRegion(MKCoordinateRegion(center: searchAnnotation.coordinate, latitudinalMeters: 100, longitudinalMeters: 100), animated: true)
    }
    
}
