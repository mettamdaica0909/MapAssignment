//
//  UIViewControllerExtension.swift
//  Assignment
//
//  Created by Mettamdaica on 5/2/18.
//  Copyright © 2018 Duy Le. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlert(_ message: String? = nil, okHandler: (() -> Void)? = nil) -> Void {
        let alertVC = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
            alertVC.dismiss(animated: true, completion: {
                
            })
            okHandler?()
        }))
        self.present(alertVC, animated: true, completion: nil)
    }
}
