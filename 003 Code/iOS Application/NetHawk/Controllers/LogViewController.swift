//
//  LogViewController.swift
//  PackeTracker
//
//  Created by mobicom on 6/4/24.
//

import UIKit

class LogViewController: UIViewController {
    
    @IBOutlet weak var logTextView: UITextView!
    @IBOutlet weak var containerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad : LogView")
        
        logTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        logTextView.isEditable = false
        
        containerView.layer.cornerRadius = 10
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
    }
    
    @IBAction func dismissBtnTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
