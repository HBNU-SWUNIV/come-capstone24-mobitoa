//
//  ConnectionViewController.swift
//  NetHawk
//
//  Created by mobicom on 6/6/24.
//

import UIKit
import CocoaMQTT

class ConnectionViewController: UIViewController {

    // MARK: - UI Outlets
    @IBOutlet weak var logoLabel: UIButton!
    @IBOutlet weak var inputLabelOne: UILabel!
    @IBOutlet weak var inputLabelTwo: UILabel!
    @IBOutlet weak var tfFrameOne: UIView!
    @IBOutlet weak var tfFrameTwo: UIView!
    @IBOutlet weak var serialNumberTextField: UITextField!
    @IBOutlet weak var aliasTextField: UITextField!
    @IBOutlet weak var pairingBtn: UIButton!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var portSegmentedControl: UISegmentedControl!
    
    // MARK: - LifeCycle and UI Design
    override func viewDidLoad() {
        super.viewDidLoad()
        self.logoLabel.alpha = 0.0
        self.inputLabelOne.alpha = 0.0
        self.inputLabelTwo.alpha = 0.0
        self.tfFrameOne.alpha = 0.0
        self.tfFrameTwo.alpha = 0.0
        self.pairingBtn.alpha = 0.0
        self.portSegmentedControl.alpha = 0.0
        self.logoImageView.alpha = 0.0
        self.serialNumberTextField.text = ""
        self.aliasTextField.text = ""

        frameConfig(to: tfFrameOne)
        frameConfig(to: tfFrameTwo)

        serialNumberTextField.delegate = self
        aliasTextField.delegate = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        serialNumberTextField.clearButtonMode = .whileEditing
        aliasTextField.clearButtonMode = .whileEditing

        // 만약 이미 저장된 정보가 있으면 MQTT 연결 시도
        if let credentials = KeychainManager.shared.load() {
            let serialNumber = credentials.serialNumber
            let alias = credentials.alias

            if !serialNumber.isEmpty && !alias.isEmpty {
                connectToMQTTBroker(serialNumber: serialNumber, alias: alias)
            }
        }

        // 저장된 네트워크 타입 불러오기
        let savedNetworkType = UserDefaults.standard.integer(forKey: "SelectedNetworkType")
        portSegmentedControl.selectedSegmentIndex = savedNetworkType
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.applyAnimations()
        }
    }

    // MARK: - Port 설정 세그먼트 컨트롤
    @IBAction func portSegmentedChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            UserDefaults.standard.set(portSegmentedControl.selectedSegmentIndex, forKey: "SelectedNetworkType")
        case 1:
            UserDefaults.standard.set(portSegmentedControl.selectedSegmentIndex, forKey: "SelectedNetworkType")
        default:
            break
        }
    }
    // MARK: - UI 설정 함수들
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

    func applyAnimations() {
        UIView.animate(withDuration: 1, delay: 0.1, options: .curveEaseInOut, animations: {
            self.logoLabel.alpha = 1.0
        }, completion: nil)

        UIView.animate(withDuration: 1, delay: 0.2, options: .curveEaseInOut, animations: {
            self.portSegmentedControl.alpha = 1.0
        }, completion: nil)

        UIView.animate(withDuration: 1, delay: 0.3, options: .curveEaseInOut, animations: {
            self.inputLabelOne.alpha = 1.0
        }, completion: nil)

        UIView.animate(withDuration: 1, delay: 0.5, options: .curveEaseInOut, animations: {
            self.tfFrameOne.alpha = 1.0
        }, completion: nil)

        UIView.animate(withDuration: 1, delay: 0.7, options: .curveEaseInOut, animations: {
            self.inputLabelTwo.alpha = 1.0
        }, completion: nil)

        UIView.animate(withDuration: 1, delay: 0.9, options: .curveEaseInOut, animations: {
            self.tfFrameTwo.alpha = 1.0
        }, completion: nil)

        UIView.animate(withDuration: 1, delay: 1.1, options: .curveEaseInOut, animations: {
            self.pairingBtn.alpha = 1.0
            self.pairingBtn.isEnabled = false
        }, completion: nil)

        UIView.animate(withDuration: 1, delay: 1.3, options: .curveEaseInOut, animations: {
            self.logoImageView.alpha = 0.1
        }, completion: nil)
    }

    // MARK: - MQTT 연결 및 관련 메서드

    @IBAction func pairingBtnTapped(_ sender: UIButton) {
        let serialNumber = serialNumberTextField.text ?? ""
        let alias = aliasTextField.text ?? ""
        
        if portSegmentedControl.selectedSegmentIndex == 0 {
            MQTTService.shared.configure(clientID: alias, host: "203.230.104.207", port: 14025)
            print("internal")
        } else {
            MQTTService.shared.configure(clientID: alias, host: "203.230.104.207", port: 80)
            print("external")
        }

        // 키체인에 S/N과 별칭 저장
        KeychainManager.shared.save(serialNumber: serialNumber, alias: alias)

        connectToMQTTBroker(serialNumber: serialNumber, alias: alias)
    }

    // MQTT 브로커 연결
    func connectToMQTTBroker(serialNumber: String, alias: String) {
        // MQTT 설정
        let portIndex = UserDefaults.standard.integer(forKey: "SelectedNetworkType")
        var port = 0

        if portIndex == 0 {
            port = 14025
        } else {
            port = 80
        }

        MQTTService.shared.configure(clientID: alias, host: "203.230.104.207", port: UInt16(port))
        MQTTService.shared.connect()

        MQTTService.shared.onConnectionSuccess = { [weak self] in
            DispatchQueue.main.async {
                self?.navigateToMainViewController()
            }
        }

        MQTTService.shared.onConnectionFailure = { [weak self] in
            DispatchQueue.main.async {
                self?.presentConnectionErrorAlert()
            }
        }
    }

    // 연결 실패 시, 알림창
    func presentConnectionErrorAlert() {
        let alert = UIAlertController(title: "Connection Error", message: "Unable to connect to MQTT broker. Please check the details and try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { [weak self] _ in
            self?.pairingBtnTapped(UIButton())
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }

    // MainViewController로 이동
    private func navigateToMainViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let mainViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController") as? MainViewController {
            if let navigationController = navigationController {
                navigationController.pushViewController(mainViewController, animated: true)
            } else {
                mainViewController.modalPresentationStyle = .fullScreen
                present(mainViewController, animated: true, completion: nil)
            }
        }
    }
}

// UITextFieldDelegate 확장
extension ConnectionViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let serialNumberIsEmpty = serialNumberTextField.text?.isEmpty ?? true
        let aliasIsEmpty = aliasTextField.text?.isEmpty ?? true

        pairingBtn.isEnabled = !(serialNumberIsEmpty || aliasIsEmpty)
        return true
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
