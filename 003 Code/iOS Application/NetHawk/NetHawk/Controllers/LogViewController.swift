//
//  LogViewController.swift
//  PackeTracker
//
//  Created by mobicom on 6/4/24.
//

import UIKit

class LogViewController: UIViewController {

    @IBOutlet weak var logTableView: UITableView!

    var contentArray = [Log]()

    override func viewDidLoad() {
        super.viewDidLoad()

        let myTableViewCellNib = UINib(nibName: "DetectionMessage", bundle: nil)
        self.logTableView.register(myTableViewCellNib, forCellReuseIdentifier: "DetectionMessageCell")
        self.logTableView.rowHeight = UITableView.automaticDimension
        self.logTableView.estimatedRowHeight = 177
        self.logTableView.delegate = self
        self.logTableView.dataSource = self

        // UserDefaults에서 초기 로그 로드
        self.contentArray = LoggingService.shared.getLogs()

        // MQTT 메시지가 로깅될 때마다 테이블 뷰를 업데이트하도록 NotificationCenter 추가
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveNewLog(_:)), name: NSNotification.Name("NewLogReceived"), object: nil)
    }

    // 새로운 로그를 받았을 때 테이블 뷰를 업데이트하는 함수
    @objc func didReceiveNewLog(_ notification: Notification) {
        if let newLog = notification.userInfo?["log"] as? Log {
            // 새로운 로그를 배열의 앞쪽에 추가
            contentArray.insert(newLog, at: 0)

            // 테이블 뷰를 리로드하는 대신, 새로운 셀이 추가된 위치만 업데이트
            logTableView.beginUpdates()
            logTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            logTableView.endUpdates()

            // 새로운 셀이 추가된 후 해당 셀로 스크롤
            logTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }

    @IBAction func dismissBtnTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

extension LogViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contentArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = logTableView.dequeueReusableCell(withIdentifier: "DetectionMessageCell", for: indexPath) as! DetectionMessageCell
        let log = contentArray[indexPath.row]
        // 로그 데이터 업로드
        cell.addressOfInvaderLabel.text = log.invaderAddress
        cell.addressOfVictimLabel.text = log.victimAddress
        cell.victimDeviceLabel.text = log.victimName
        cell.timeStampLabel.text = log.timestamp
        cell.typeOfAttackLabel.text = log.type

        cell.configureCell(with: log)

        return cell
    }
}
