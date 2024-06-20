//
//  TrainNoTimeTableViewController.swift
//  iosExercise_2
//
//  Created by 莊善傑 on 2024/6/17.
//

import UIKit

class TrainNoTimeTableViewController: UIViewController {
    
    @IBOutlet weak var TrainNoTimeTableView: UITableView!
    @IBOutlet weak var LabelWidth: UILabel!
    
    var originStation : String?
    var destinationStation : String?
    var TrainNo : String?
    
    var trainNoTableInfos: [TrainNoTable] = []
    var targetLabelWidth: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.targetLabelWidth = LabelWidth.frame.width
        navigationItem.title = "\(String(describing: TrainNo!))時刻表"

        TrainNoTimeTableView.delegate = self
        TrainNoTimeTableView.dataSource = self
        let nib = UINib(nibName: "TrainNoTimeTableCell", bundle: nil)
        TrainNoTimeTableView.register(nib, forCellReuseIdentifier: "TrainNoTimeTableCell")
    }
}
extension TrainNoTimeTableViewController: UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return trainNoTableInfos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let trainNoTable = trainNoTableInfos[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrainNoTimeTableCell", for: indexPath) as! TrainNoTimeTableCell
        cell.updateLabelWidth(to: targetLabelWidth)
        let rowNumberString = String(format: "%02d", indexPath.row + 1)
        cell.stationNameLabel.text = "\(rowNumberString). \(String(describing: trainNoTable.StationNameZhTW!))高鐵站"
        if(indexPath.row == trainNoTableInfos.count - 1){
            cell.departureTimeLabel.text = "--:--"
        }
        else{
            cell.departureTimeLabel.text = trainNoTable.DepartureTime
        }
        if("\(String(describing: trainNoTable.StationNameZhTW!))高鐵站" == originStation || "\(String(describing: trainNoTable.StationNameZhTW!))高鐵站" == destinationStation ){
            cell.backgroundColor = UIColor(red: 244/255, green: 186/255, blue: 48/255, alpha: 1.0)
        }
        return cell
    }
}
