//
//  DetectionMessageCellTableViewCell.swift
//  NetHawk
//
//  Created by mobicom on 10/8/24.
//

import UIKit

class DetectionMessageCell: UITableViewCell {

    @IBOutlet weak var attackImage: UIImageView!
    @IBOutlet weak var victimDeviceLabel: UILabel!
    @IBOutlet weak var timeStampLabel: UILabel!
    @IBOutlet weak var typeOfAttackLabel: UILabel!
    @IBOutlet weak var addressOfInvaderLabel: UILabel!
    @IBOutlet weak var addressOfVictimLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        print(typeOfAttackLabel.text!)
        if (typeOfAttackLabel.text!) == "Domain Phishing" {
            attackImage.image = #imageLiteral(resourceName: "phishing")
        } else {
            attackImage.image = #imageLiteral(resourceName: "flooding")
        }
        attackImage.layer.cornerRadius = 12
        // attackImage.layer.masksToBounds = false

//        // 쉐도우 설정
//        attackImage.layer.shadowColor = UIColor.black.cgColor
//        attackImage.layer.shadowOpacity = 0.3
//        attackImage.layer.shadowOffset = CGSize(width: 3, height: 3)
//        attackImage.layer.shadowRadius = 40
        // 성능 향상을 위한 렌더링 최적화
        attackImage.layer.shouldRasterize = true
        // 레스터화 해상도 조정
        attackImage.layer.rasterizationScale = UIScreen.main.scale

    }

    // 셀의 내용을 설정하는 메서드
    func configureCell(with log: Log) {
        victimDeviceLabel.text = log.victimName
        timeStampLabel.text = log.timestamp
        typeOfAttackLabel.text = log.type
        addressOfVictimLabel.text = log.victimAddress
        addressOfInvaderLabel.text = log.invaderAddress ?? "N/A"

        // 공격 유형에 따라 이미지 설정
        if log.type == "Domain phishing" {
            attackImage.image = #imageLiteral(resourceName: "phishing")
        } else if log.type == "TCP-Flooding" || log.type == "UDP-Flooding" {
            attackImage.image = #imageLiteral(resourceName: "flooding")
        } else {
            attackImage.image = #imageLiteral(resourceName: "Sheep") // 기본 이미지
        }
    }
    //    override func setSelected(_ selected: Bool, animated: Bool) {
    //        super.setSelected(selected, animated: animated)
    //
    //        // Configure the view for the selected state
    //    }

}
