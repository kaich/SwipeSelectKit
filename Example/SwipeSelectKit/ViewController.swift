//
//  ViewController.swift
//  SwipeSelectKit
//
//  Created by chengkai1853@163.com on 05/23/2019.
//  Copyright (c) 2019 chengkai1853@163.com. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 100
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DemoCell", for: indexPath)
        cell.backgroundColor = UIColor.random
        return cell
    }
    
}


extension UIColor {
    /**
     * Returns random color
     * ## Examples:
     * self.backgroundColor = UIColor.random
     */
    static var random: UIColor {
        let r:CGFloat  = .random(in: 0...1)
        let g:CGFloat  = .random(in: 0...1)
        let b:CGFloat  = .random(in: 0...1)
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
}
