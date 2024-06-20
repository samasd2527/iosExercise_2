//
//  RoutePlanningViewController.swift
//  iosExercise_2
//
//  Created by 莊善傑 on 2024/6/16.
//

import UIKit

struct GeneralTimetableResponse: Decodable {
    let GeneralTimetable: GeneralTimetable
}

struct GeneralTimetable: Decodable {
    let StopTimes: [StopTime1]
}

struct StopTime1: Decodable {
    let StationName: StationName
    let DepartureTime: String?
}

struct TrainNoTable: Decodable {
    let StationNameZhTW: String?
    let DepartureTime: String?
}

class RoutePlanningViewController: UIViewController {

    @IBOutlet weak var RoutePlanningTableView: UITableView!
    @IBOutlet weak var labelWidth: UILabel!
    
    var dailyTimeInfos: [DailyTime] = []
    var trainNoTableInfos: [TrainNoTable] = []
    
    var originStation : String?
    var destinationStation : String?
    var targetLabelWidth: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        targetLabelWidth = labelWidth.frame.width
        navigationItem.title = "\(String(describing: removeSubstring(originStation!)))->\(String(describing: removeSubstring(destinationStation!)))"
       
        RoutePlanningTableView.delegate = self
        RoutePlanningTableView.dataSource = self
        let nib = UINib(nibName: "RoutePlanningTableViewCell", bundle: nil)
        RoutePlanningTableView.register(nib, forCellReuseIdentifier: "RoutePlanningTableViewCell")
    }
    
    func buildGeneralTimetableURL(for trainNo: String) -> URL? {
        let apiUrlString = "https://tdx.transportdata.tw/api/basic/v2/Rail/THSR/GeneralTimetable/TrainNo/\(trainNo)?%24top=30&%24format=JSON"
        return URL(string: apiUrlString)
    }

    func getGeneralTimetable(trainNo: String, accessToken: String, completion: @escaping ([TrainNoTable]) -> Void) {
        guard let url = buildGeneralTimetableURL(for: trainNo) else {
            print("URL 構建失敗")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("獲取時刻表資料失敗: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("獲取時刻表資料失敗: 無數據返回")
                return
            }
            do {
                let timetableResponse = try JSONDecoder().decode([GeneralTimetableResponse].self, from: data)
                if let firstResponse = timetableResponse.first {
                    for stopTime in firstResponse.GeneralTimetable.StopTimes {
                        let stationName = stopTime.StationName.Zh_tw
                        let departureTime = stopTime.DepartureTime
                        let trainNoTable = TrainNoTable(StationNameZhTW: stationName, DepartureTime: departureTime)
                        self.trainNoTableInfos.append(trainNoTable)
                    }
                }
                completion(self.trainNoTableInfos)
            } catch {
                print("解析時刻表資料失敗: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
    func removeSubstring(_ originalString: String) -> String {
        if let range = originalString.range(of: "高鐵站") {
            var modifiedString = originalString
            modifiedString.removeSubrange(range)
            return modifiedString.trimmingCharacters(in: .whitespaces)
        }
        return originalString
    }
}

extension RoutePlanningViewController: UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return dailyTimeInfos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        func convertStringToTime(_ timeString: String) -> Date? {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            return dateFormatter.date(from: timeString)
        }

        func calculateMinutesBetweenTimes(start: Date, end: Date) -> Int {
            let interval = end.timeIntervalSince(start)
            return Int(interval / 60)
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "RoutePlanningTableViewCell", for: indexPath) as! RoutePlanningTableViewCell
        let routePlanning = dailyTimeInfos[indexPath.row]
        cell.trainNo.text = routePlanning.TrainNo
        let direction = routePlanning.Direction
        cell.direction.text = direction == 0 ? "南下" : "北上"
        cell.updateLabelWidth(to: targetLabelWidth)
        cell.originDepartureTime.text = routePlanning.OriginDepartureTime
        cell.destinationArrivalTime.text = routePlanning.DestinationArrivalTime
        if let departureTime = convertStringToTime(routePlanning.OriginDepartureTime),
        let arrivalTime = convertStringToTime(routePlanning.DestinationArrivalTime) {
            
        let driveTimeMinutes = calculateMinutesBetweenTimes(start: departureTime, end: arrivalTime)
             cell.driveTime.text = "\(driveTimeMinutes) 分鐘"
        } else {
            cell.driveTime.text = "時間格式錯誤"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let routePlanning = dailyTimeInfos[indexPath.row]
        getAccessToken { accessToken in
            if let token = accessToken {
                self.trainNoTableInfos.removeAll()
                self.getGeneralTimetable(trainNo: routePlanning.TrainNo, accessToken: token) { trainNoTimeTable in
                    DispatchQueue.main.async {
                        if let trainNoTimeVC = self.storyboard?.instantiateViewController(withIdentifier: "TrainNoTimeTableViewController") as? TrainNoTimeTableViewController {
                            trainNoTimeVC.trainNoTableInfos = self.trainNoTableInfos
                            trainNoTimeVC.originStation = self.originStation
                            trainNoTimeVC.destinationStation = self.destinationStation
                            trainNoTimeVC.TrainNo = routePlanning.TrainNo
                            tableView.deselectRow(at: indexPath, animated: true)
                            self.navigationController?.pushViewController(trainNoTimeVC, animated: true)
                        }
                    }
                }
            }
        }
    }
}

