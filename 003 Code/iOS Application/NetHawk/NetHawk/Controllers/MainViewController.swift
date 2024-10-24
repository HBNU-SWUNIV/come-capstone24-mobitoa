//
//  MainViewController2.swift
//  NetHawk
//
//  Created by mobicom on 9/10/24.
//

import UIKit
import UserNotifications
import FSPagerView

class MainViewController: UIViewController, FSPagerViewDataSource, FSPagerViewDelegate {

    // MARK: - FSPagerView
    @IBOutlet weak var pagerView: FSPagerView! {
        didSet {
            self.pagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")

            // 화면 크기에 비례한 아이템 크기 설정
            let screenWidth = UIScreen.main.bounds.width
            let itemWidth = screenWidth * 0.65
            let itemHeight = itemWidth * 135/155
            self.pagerView.itemSize = CGSize(width: itemWidth, height: itemHeight)
            self.pagerView.interitemSpacing = 50
            self.pagerView.isInfinite = true
            self.pagerView.transformer = FSPagerViewTransformer(type: .ferrisWheel)
        }

    }

    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return images.count // 총 4개의 페이지
    }

    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)

        // SF Symbol 이미지 설정
        if let imageView = cell.imageView {
            imageView.image = UIImage(named: images[index])
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 8 // 이미지도 모서리를 둥글게
            imageView.layer.masksToBounds = true
        }

        return cell
    }

    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        pagerView.deselectItem(at: index, animated: true) // 선택된 상태 해제

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        switch index {
        case 0:
            // 첫 번째 페이지로 이동
            if let firstVC = storyboard.instantiateViewController(withIdentifier: "LogViewController") as? LogViewController {
                firstVC.modalPresentationStyle = .fullScreen
                present(firstVC, animated: true, completion: nil)
            }
        case 1:
            // 두 번째 페이지로 이동
            if let secondVC = storyboard.instantiateViewController(withIdentifier: "StatViewController") as? StatViewController {
                secondVC.modalPresentationStyle = .fullScreen
                present(secondVC, animated: true, completion: nil)
            }
        case 2:
            // 세 번째 페이지로 이동
            if let thirdVC = storyboard.instantiateViewController(withIdentifier: "AccessViewController") as? AccessViewController {
                thirdVC.modalPresentationStyle = .fullScreen
                present(thirdVC, animated: true, completion: nil)
            }
        case 3:
            // 네 번째 페이지로 이동
            if let fourVC = storyboard.instantiateViewController(withIdentifier: "OptionViewController") as? OptionViewController {
                // 화면 중앙에서 시트처럼 올라오게 설정
                fourVC.modalPresentationStyle = .pageSheet

                if let sheet = fourVC.sheetPresentationController {
                    // 시트 크기 설정
                    sheet.detents = [.large(), .medium()]

                    // 모서리 둥글기 설정
                    sheet.preferredCornerRadius = 24

                    // 그래버 표시
                    sheet.prefersGrabberVisible = true

                    // 배경 딤 처리
                    sheet.largestUndimmedDetentIdentifier = nil

                    // 스크롤 시 확장 방지
                    sheet.prefersScrollingExpandsWhenScrolledToEdge = true

                    // 드래그로 닫기 가능
                    sheet.prefersEdgeAttachedInCompactHeight = true

                    // 상단 여백 설정
                    sheet.selectedDetentIdentifier = .medium
                }

                // 모달 스타일 설정
                fourVC.modalPresentationStyle = .pageSheet

                present(fourVC, animated: true, completion: nil)
            }

        default:
            break
        }
    }

    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!

    let images = ["loger", "stat", "bw", "option"]

    // MARK: - UI
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pagerView.dataSource = self
        self.pagerView.delegate = self

        if let credentials = KeychainManager.shared.load() {
            // let serialNumber = credentials.serialNumber
            let alias = credentials.alias

            deviceLabel.text = "My Device : \(alias)"
        }

        frameConfig(to: statusView)
        
        // MQTT 초기 상태 업데이트
        updateStatusLabel()

        // MQTTService에서 상태 콜백 등록
        setupMQTTStatusCallbacks()

        // 알림 권한 요청
        requestNotificationAuthorization()
    }

    // TODO: 사용자가 외부에서 알림 권한을 제거한 경우? --> 추후 생각이 필요할듯.
    // 알림 권한 요청
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()

        let alreadyAuthed = UserDefaults.standard.bool(forKey: "alreadyAuthed")

        if !alreadyAuthed {
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("Notification authorization error: \(error)")
                    // 권한 요청이 실패했거나 거부된 경우
                    UserDefaults.standard.set(1, forKey: "notificationEnabled")
                } else {
                    // 권한 요청이 성공적으로 승인된 경우
                    UserDefaults.standard.set(0, forKey: "notificationEnabled")
                }
                UserDefaults.standard.set(true, forKey: "alreadyAuthed")
            }
        }
    }

    func frameConfig(to view: UIView) {
        let cornerRadius: CGFloat = 10
        let shadowColor: UIColor = .black
        let shadowOpacity: Float = 0.3
        let shadowOffset: CGSize = CGSize(width: 0, height: 2)
        let shadowRadius: CGFloat = 4

        view.layer.cornerRadius = cornerRadius
        view.layer.masksToBounds = false
        view.layer.shadowColor = shadowColor.cgColor
        view.layer.shadowOpacity = shadowOpacity
        view.layer.shadowOffset = shadowOffset
        view.layer.shadowRadius = shadowRadius
    }

    // MARK: - MQTT 상태 설정
    func setupMQTTStatusCallbacks() {
        MQTTService.shared.onPingReceived = { [weak self] in
            DispatchQueue.main.async {
                self?.statusLabel.text = "Checking connection..."
                self?.statusLabel.textColor = .gray
            }
        }

        MQTTService.shared.onPongReceived = { [weak self] in
            DispatchQueue.main.async {
                self?.statusLabel.text = "Server Online 🟢"
                self?.statusLabel.textColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
            }
        }

        MQTTService.shared.onDisconnected = { [weak self] in
            DispatchQueue.main.async {
                self?.statusLabel.text = "Checking connection... 🟠"
                self?.statusLabel.textColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
            }
        }

        MQTTService.shared.onConnectionSuccess = { [weak self] in
            DispatchQueue.main.async {
                self?.statusLabel.text = "Server Online 🟢"
                self?.statusLabel.textColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
            }}
    }

    func updateStatusLabel() {
        if MQTTService.shared.isConnected() {
            statusLabel.text = "Server Online 🟢"
            statusLabel.textColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        } else {
            statusLabel.text = "Checking connection... 🟠"
            statusLabel.textColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
        }
    }
}
