//
//  RoutePlanningTableViewCell.swift
//  iosExercise_2
//
//  Created by 莊善傑 on 2024/6/16.
//

import UIKit

class RoutePlanningTableViewCell: UITableViewCell {
    
    @IBOutlet weak var direction: UILabel!
    @IBOutlet weak var trainNo: UILabel!
    @IBOutlet weak var originDepartureTime: UILabel!
    @IBOutlet weak var driveTime: UILabel!
    @IBOutlet weak var destinationArrivalTime: UILabel!
    @IBOutlet weak var directionAndNo: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        directionAndNo.layer.cornerRadius = 10
        directionAndNo.layer.masksToBounds = true
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func updateLabelWidth(to width: CGFloat) {
        driveTime.widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    
}
