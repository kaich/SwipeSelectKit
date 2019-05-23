
//
//  SecondViewController.swift
//  SwipeSelectKit_Example
//
//  Created by mk on 2019/5/23.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import SwipeSelectKit

class SecondViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var collectionView: SwipeSelectingCollectionView!
    
    var selectedIndexPaths = [IndexPath]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let btnToggle = UIBarButtonItem(title: "Close/Open Swipe", style: .plain, target: self, action: #selector(toggleSwipe))
        self.navigationItem.rightBarButtonItem = btnToggle
        
        collectionView.isSelectedHandler = { [weak self] indexPath in
            return self?.selectedIndexPaths.contains(indexPath) ?? false
        }

    }
    
    @objc func toggleSwipe() {
        self.collectionView.isSwipeSelectingEnabled = !self.collectionView.isSwipeSelectingEnabled
    }
    

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1000
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DemoCell", for: indexPath) as! DemoCollectionViewCell
        cell.backgroundColor = UIColor.random
        if selectedIndexPaths.contains(indexPath) {
            cell.ivImage.isHidden = false
        } else {
            cell.ivImage.isHidden = true
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var isSelected = false
        if let selectedIndex = selectedIndexPaths.firstIndex(of: indexPath) {
            isSelected = false
            selectedIndexPaths.remove(at: selectedIndex)
        } else {
            isSelected = true
            selectedIndexPaths.append(indexPath)
        }
       
        if let cell = collectionView.cellForItem(at: indexPath) as? DemoCollectionViewCell {
            if isSelected {
                cell.ivImage.isHidden = false
            } else {
                cell.ivImage.isHidden = true
            }
        }

    }

}
