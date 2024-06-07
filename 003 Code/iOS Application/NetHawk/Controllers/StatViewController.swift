//
//  StatViewController.swift
//  PackeTracker
//
//  Created by mobicom on 6/4/24.
//

import UIKit

class StatViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad : StatView")
        
    }
    
    @IBAction func dissmissBtnTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
