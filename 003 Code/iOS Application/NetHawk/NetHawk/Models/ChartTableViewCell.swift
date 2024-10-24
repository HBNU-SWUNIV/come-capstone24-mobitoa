//
//  ChartTableViewCell.swift
//  NetHawk
//
//  Created by mobicom on 10/22/24.
//

import UIKit
import SwiftUI

class ChartTableViewCell: UITableViewCell {

    @IBOutlet weak var chartContainer: UIView!

    // 차트를 설정하는 메소드
    func configure(with chartData: ChartData) {
        let hostingController = UIHostingController(rootView: chartData.chartView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        // chartContainer에 SwiftUI 차트 추가
        chartContainer.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: chartContainer.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: chartContainer.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: chartContainer.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: chartContainer.bottomAnchor)
        ])
    }
}
