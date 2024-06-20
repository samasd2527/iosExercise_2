//
//  TrainNoTimeTableCell.swift
//  iosExercise_2
//
//  Created by 莊善傑 on 2024/6/17.
//

import UIKit

class TrainNoTimeTableCell: UITableViewCell {
    
    @IBOutlet weak var departureTimeLabel: UILabel!
    @IBOutlet weak var stationNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func updateLabelWidth(to width: CGFloat) {
        stationNameLabel.widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    
}
