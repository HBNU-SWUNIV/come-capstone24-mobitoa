//
//  LauchScreenViewController.swift
//  NetHawk
//
//  Created by mobicom on 6/6/24.
//

import UIKit

class SplashViewController: UIViewController {
    
    // MARK: - UI Outlets
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var developedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("viewDidLoad : SplashView")
        self.logoImageView.alpha = 0.0
        self.developedLabel.alpha = 0.0
        
        // 그림자 효과 추가
        logoImageView.layer.shadowColor = UIColor.black.cgColor
        logoImageView.layer.shadowOpacity = 0.5
        logoImageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        logoImageView.layer.shadowRadius = 4
        
        // 애니메이션 효과 추가
        UIView.animate(withDuration: 2, delay: 0.1, options: .curveEaseInOut, animations: {
            self.logoImageView.alpha = 1.0
        }, completion: nil)
        
        UIView.animate(withDuration: 2, delay: 0.1, options: .curveEaseInOut, animations: {
            self.developedLabel.alpha = 1.0
        }, completion: { finished in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                guard let VC = storyboard.instantiateViewController(identifier: "Main") as? ConnectionViewController else {return}
                VC.modalPresentationStyle = .fullScreen
                self.present(VC, animated: false, completion: nil)
            }
        })
    }
}
