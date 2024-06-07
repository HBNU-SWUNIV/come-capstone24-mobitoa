//
//  ConnectionViewController.swift
//  NetHawk
//
//  Created by mobicom on 6/6/24.
//

import UIKit

class ConnectionViewController: UIViewController {
    
    // MARK: - UI Outlets
    @IBOutlet weak var logoLabel: UIButton!
    @IBOutlet weak var inputLabelOne: UILabel!
    @IBOutlet weak var inputLabelTwo: UILabel!
    @IBOutlet weak var tfFrameOne: UIView!
    @IBOutlet weak var tfFrameTwo: UIView!
    @IBOutlet weak var brokerTextField: UITextField!
    @IBOutlet weak var macTextField: UITextField!
    @IBOutlet weak var pairingBtn: UIButton!
    @IBOutlet weak var logoImageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad : ConnectionView")
        self.logoLabel.alpha = 0.0
        self.inputLabelOne.alpha = 0.0
        self.inputLabelTwo.alpha = 0.0
        self.tfFrameOne.alpha = 0.0
        self.tfFrameTwo.alpha = 0.0
        self.pairingBtn.alpha = 0.0
        self.logoImageView.alpha = 0.0
        self.brokerTextField.text = ""
        self.macTextField.text = ""
        
        frameConfig(to: tfFrameOne)
        frameConfig(to: tfFrameTwo)
        
        brokerTextField.delegate = self
        macTextField.delegate = self
        
    }
    
    // SplashView에서 DispatchQueue.main.asyncAfter를 사용하여
    // 일정 시간 지연 후에 본 페이지로 오기 때문에 타이밍 문제가 존재했음.
    // viewDidAppear로 이전 타이밍이 끝나고 본 작업을 시행
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 1초 지연 후에 애니메이션 시작
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.applyAnimations()
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
    func applyAnimations() {
        UIView.animate(withDuration: 1, delay: 0.1, options: .curveEaseInOut, animations: {
            self.logoLabel.alpha = 1.0
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
    
    
    @IBAction func pairingBtnTapped(_ sender: UIButton) {
        let broker = brokerTextField.text ?? ""
        let mac = macTextField.text ?? ""
        
        KeychainManager.shared.save(broker: broker, mac: mac)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let mainViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController") as? MainViewController {
            print("MainViewController 인스턴스 생성 성공")
            
            if let navigationController = navigationController {
                print("NavigationController 있음")
                navigationController.pushViewController(mainViewController, animated: true)
            } else {
                print("NavigationController 없음")
                mainViewController.modalPresentationStyle = .fullScreen
                present(mainViewController, animated: true, completion: nil)
            }
        } else {
            print("MainViewController 인스턴스 생성 실패")
        }
        
        if let (broker, mac) = KeychainManager.shared.load() {
                    print("Broker: \(broker)")
                    print("MAC: \(mac)")
                    // 로드된 값을 사용하여 필요한 작업 수행
                } else {
                    print("Keychain에서 값을 찾을 수 없습니다.")
                }
        
    }
}

extension ConnectionViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == brokerTextField {
            // 브로커 텍스트필드 입력 시 버튼 숨김 여부 결정
            let brokerTextIsEmpty = brokerTextField.text?.isEmpty ?? true
            let macTextIsEmpty = macTextField.text?.isEmpty ?? true
            
            if brokerTextIsEmpty || macTextIsEmpty {
                pairingBtn.isEnabled = false
            } else {
                pairingBtn.isEnabled = true
            }
            
            return true
            
        } else if textField == macTextField {
            let currentText = textField.text ?? ""
            let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
            
            _ = "^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$"
            
            let formattedText = prospectiveText.replacingOccurrences(of: ":", with: "").replacingOccurrences(of: "-", with: "")
            
            if formattedText.count > 12 {
                return false
            }
            
            let macAddress = formatMACAddress(formattedText)
            
            textField.text = macAddress
            
            // MAC 텍스트필드 입력 시 버튼 숨김 여부 결정
            let brokerTextIsEmpty = brokerTextField.text?.isEmpty ?? true
            let macTextIsEmpty = macTextField.text?.isEmpty ?? true
            
            if brokerTextIsEmpty || macTextIsEmpty {
                pairingBtn.isEnabled = false
            } else {
                pairingBtn.isEnabled = true
            }
            
            return false
        }
        return true
    }
    func formatMACAddress(_ macAddress: String) -> String {
        var formattedMACAddress = ""
        var index = 0
        
        for char in macAddress {
            formattedMACAddress.append(char)
            
            if (index + 1) % 2 == 0 && index < macAddress.count - 1 {
                formattedMACAddress.append(":")
            }
            
            index += 1
        }
        
        return formattedMACAddress
    }
    
}
