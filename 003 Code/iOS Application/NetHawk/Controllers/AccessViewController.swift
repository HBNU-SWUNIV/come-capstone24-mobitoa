//
//  AccessControlViewController.swift
//  PackeTracker
//
//  Created by mobicom on 6/4/24.
//

import UIKit

class AccessViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad : AccessView")
    }
    
    @IBAction func dissmissBtnTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
