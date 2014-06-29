//
//  ViewController.swift
//  Lexibomb
//
//  Created by Alan Westbrook on 6/29/14.
//  Copyright (c) 2014 Elastic Dog. All rights reserved.
//

import UIKit

class ViewController: UICollectionViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    struct Point {
        let x: Int
        let y: Int
        
        func asString() -> String {
            return String("(\(x), \(y))")
        }
    }
    
    var tiles: String[]
    let columnCount: Int
    
    init(coder aDecoder: NSCoder!)  {
        tiles = ["one", "two", "three", "four", "5", "6", "7"]
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            columnCount = 14
        } else {
            columnCount = 5
        }
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell! {
        
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as UICollectionViewCell
        
        var label = cell.viewWithTag(1001) as UILabel
        
        label.text = self.tiles[indexPath.row]
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int {
        return self.tiles.count
    }
    
    override func collectionView(collectionView: UICollectionView!, didSelectItemAtIndexPath indexPath: NSIndexPath!) {
        NSLog("Pressed %@", pointForIndexPath(indexPath).asString())
    }
    
    func pointForIndexPath(indexPath: NSIndexPath) -> Point {
        var row = indexPath.row / self.columnCount
        var column = indexPath.row % self.columnCount
        return Point(x: row, y: column)
    }
    
}

