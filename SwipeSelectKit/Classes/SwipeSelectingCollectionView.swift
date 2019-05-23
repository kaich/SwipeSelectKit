//
//  SwipeSelectingCollectionView.swift
//  TileTime
//
//  Created by Shangen Zhang on 2019/3/26.
//  Copyright © 2019 Mi Cheng. All rights reserved.
//

import UIKit

public class SwipeSelectingCollectionView: UICollectionView {

    /// 判断IndexPath是否选中状态
    public var isSelectedHandler: ((IndexPath) -> Bool?)?
    /// 滑动选择滚动范围（默认顶部60、底部60）
    public var scrollPadding: CGFloat = 60
    /// 滚动速度
    public var speed: CGFloat = 1
    /// 刷新距离
    public var refreshDistance: CGFloat = 60
    /// 滑动选择是否可用(禁用之后就是普通的UICollectionView
    public var isSwipeSelectingEnabled = true {
        didSet {
            if self.isSwipeSelectingEnabled {
                enableSwipeSelecting()
            } else {
                disableSwipeSelecting()
            }
        }
    }
    
    private var currentPoint: CGPoint?
    private var beginIndexPath: IndexPath?
    private var selectingRange: ClosedRange<IndexPath>?
    private var selectingMode: SelectingMode = .selecting
    private var selectingIndexPaths = Set<IndexPath>()
    private var oldContentOffsetY: CGFloat = 0

	private enum SelectingMode {
		case selecting, deselecting
	}

	lazy var panSelectingGestureRecognizer: UIGestureRecognizer = {
		let gestureRecognizer = SwipeSelectingGestureRecognizer(
			target: self,
			action: #selector(SwipeSelectingCollectionView.didPanSelectingGestureRecognizerChange(gestureRecognizer:)))
		return gestureRecognizer
	} ()

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override public init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
		super.init(frame: frame, collectionViewLayout: layout)
        enableSwipeSelecting()
	}
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        enableSwipeSelecting()
    }
    
    deinit {
        disableSwipeSelecting()
    }
    
    private func enableSwipeSelecting() {
        panSelectingGestureRecognizer.delegate = self
        addGestureRecognizer(panSelectingGestureRecognizer)
        addObserver(self, forKeyPath: #keyPath(contentOffset), options: [.old, .new], context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(endTouch), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    private func disableSwipeSelecting() {
        panSelectingGestureRecognizer.delegate = nil
        removeGestureRecognizer(panSelectingGestureRecognizer)
        removeObserver(self, forKeyPath: #keyPath(contentOffset))
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func endTouch() {
        endScroll()
        currentPoint = nil
        beginIndexPath = nil
        selectingRange = nil
        selectingIndexPaths.removeAll()
    }

	@objc private func didPanSelectingGestureRecognizerChange(gestureRecognizer: UIPanGestureRecognizer) {
		let point = gestureRecognizer.location(in: self)
        let vpoint = panSelectingGestureRecognizer.location(in: superview)
        currentPoint = vpoint
        switch gestureRecognizer.state {
        case .began:
            self.beginIndexPath = indexPathForItem(at: point)
            if let indexPath = beginIndexPath,
                let isSelected = self.isSelectedHandler?(indexPath) {
                selectingMode = (isSelected ? .deselecting : .selecting)
                setSelection(!isSelected, indexPath: indexPath)
            } else {
                selectingMode = .selecting
            }
        case .changed:
			handleChangeOf(gestureRecognizer: gestureRecognizer)
        default:
            endTouch()
		}
	}
    
    

	private func handleChangeOf(gestureRecognizer: UIGestureRecognizer) {
		let point = gestureRecognizer.location(in: self)
        guard var beginIndexPath = self.beginIndexPath,
            var endIndexPath = indexPathForItem(at: point) else { return }
        
		if endIndexPath < beginIndexPath {
            swap(&beginIndexPath, &endIndexPath)
		}
		let range = ClosedRange(uncheckedBounds: (beginIndexPath, endIndexPath))
		guard range != selectingRange else {
            if !isStartScrolling {
                beginScroll()
            }
            return
        }
		var positiveIndexPaths: [IndexPath]!
		var negativeIndexPaths: [IndexPath]!
		if let selectingRange = selectingRange {
			if range.lowerBound == selectingRange.lowerBound {
				if range.upperBound < selectingRange.upperBound {
					negativeIndexPaths = indexPaths(in:
						ClosedRange(uncheckedBounds: (range.upperBound, selectingRange.upperBound)))
					negativeIndexPaths.removeFirst()
				} else {
					positiveIndexPaths = indexPaths(in: ClosedRange(uncheckedBounds: (selectingRange.upperBound, range.upperBound)))
				}
			} else if range.upperBound == selectingRange.upperBound {
				if range.lowerBound > selectingRange.lowerBound {
					negativeIndexPaths = indexPaths(in:
						ClosedRange(uncheckedBounds: (selectingRange.lowerBound, range.lowerBound)))
					negativeIndexPaths.removeLast()
				} else {
					positiveIndexPaths = indexPaths(in: ClosedRange(uncheckedBounds: (range.lowerBound, selectingRange.lowerBound)))
				}
			} else {
				negativeIndexPaths = indexPaths(in: selectingRange)
				positiveIndexPaths = indexPaths(in: range)
			}
		} else {
			positiveIndexPaths = indexPaths(in: range)
		}
		for indexPath in negativeIndexPaths ?? [] {
			doSelection(at: indexPath, isPositive: false)
		}
		for indexPath in positiveIndexPaths ?? [] {
			doSelection(at: indexPath, isPositive: true)
		}
		selectingRange = range
        
        if !isStartScrolling {
            beginScroll()
        }
	}
    
    private var isStartScrolling = false
    private func beginScroll() {
        guard let point = currentPoint else {
            return
        }
        
        let y = point.y
        let bottom = frame.origin.y + frame.height
        let top = frame.origin.y
        
        let scrollTask: ((Bool) -> ()) = { isToUp in
            let offset = isToUp ? -self.speed : self.speed
            let duration = 0.005
            self.contentOffset = CGPoint(x: 0, y: self.contentOffset.y + offset)

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.beginScroll()
            }
        }
        
        if y >= (bottom - scrollPadding) && contentOffset.y <= (contentSize.height - bounds.height) {
            isStartScrolling = true
            scrollTask(false)
        } else if y <= (top + scrollPadding) && contentOffset.y > 0 {
            scrollTask(true)
        } else {
            endScroll()
        }
    }
    
    private func endScroll() {
        isStartScrolling = false
    }

	private func doSelection(at indexPath: IndexPath, isPositive: Bool) {
		// Ignore the begin index path, it's already taken care of when the gesture recognizer began.
		guard indexPath != beginIndexPath else { return }
		guard let isSelected = isSelectedHandler?(indexPath) else { return }
		let expectedSelection: Bool = {
			switch selectingMode {
			case .selecting: return isPositive
			case .deselecting: return !isPositive
			}
		} ()
		if isSelected != expectedSelection {
			if isPositive {
				selectingIndexPaths.insert(indexPath)
			}
			if selectingIndexPaths.contains(indexPath) {
				setSelection(expectedSelection, indexPath: indexPath)
				if !isPositive {
					selectingIndexPaths.remove(indexPath)
				}
			}
		}
	}

	private func setSelection(_ selected: Bool, indexPath: IndexPath) {
        delegate?.collectionView?(self, didSelectItemAt: indexPath)
	}

	private func indexPaths(in range: ClosedRange<IndexPath>) -> [IndexPath] {
		var indexPaths = [IndexPath]()
		let beginSection = range.lowerBound.section
		let endSection = range.upperBound.section
		guard beginSection != endSection else {
			for row in range.lowerBound.row...range.upperBound.row {
				indexPaths.append(IndexPath(row: row, section: beginSection))
			}
			return indexPaths
		}
		for row in range.lowerBound.row..<dataSource!.collectionView(self, numberOfItemsInSection: beginSection) {
			indexPaths.append(IndexPath(row: row, section: beginSection))
		}
		for row in 0...range.upperBound.row {
			indexPaths.append(IndexPath(row: row, section: endSection))
		}
		for section in (range.lowerBound.section + 1)..<range.upperBound.section {
			for row in 0..<dataSource!.collectionView(self, numberOfItemsInSection: section) {
				indexPaths.append(IndexPath(row: row, section: section))
			}
		}
		return indexPaths
	}

}

extension SwipeSelectingCollectionView: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let interactivePopGestureRecognizer = self.viewController?.navigationController?.interactivePopGestureRecognizer
        if interactivePopGestureRecognizer?.state == .possible && interactivePopGestureRecognizer?.isEnabled == true {
            return true
        }
        return false
    }
    
}

extension SwipeSelectingCollectionView {
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(contentOffset) {
            if abs(contentOffset.y - oldContentOffsetY) > refreshDistance {
                handleChangeOf(gestureRecognizer: panSelectingGestureRecognizer)
                oldContentOffsetY = contentOffset.y
            }
        }
    }
    
}

extension UIView {
    fileprivate var viewController: UIViewController? {
        return getViewController()
    }
    
    private func getViewController() -> UIViewController? {
        guard let nextResponder = self.next else { return nil }
        
        if  nextResponder.isKind(of: UIViewController.self) {
            return nextResponder as? UIViewController
        }
        
        return (nextResponder as? UIView)?.getViewController()
    }
}
