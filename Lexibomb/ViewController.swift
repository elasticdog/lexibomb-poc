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
        let x:Int
        let y:Int
        
        func asString() -> String {
            return String("(\(x), \(y))")
        }
    }
    
    struct Tile {
        var display:String
        var data:String
    }
    
    var tiles: Tile[]
    let columnCount: Int
    
    init(coder aDecoder: NSCoder!)  {
        
        var rowCount:Int = 5
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            columnCount = 12
        } else {
            columnCount = 5
        }
        
        var count = rowCount * columnCount
        tiles = Array<Tile>(count: count, repeatedValue: Tile(display: "*", data: ""))
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
        
        // Update the data value here for convenience
        var tile = self.tiles[indexPath.row]
        tile.data = String("\(indexPath.row)")
        self.tiles[indexPath.row] = tile
        
        var label = cell.viewWithTag(1001) as UILabel
        label.text = tile.display
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int {
        return self.tiles.count
    }
    
    override func collectionView(collectionView: UICollectionView!, didSelectItemAtIndexPath indexPath: NSIndexPath!) {
        NSLog("Pressed %@", pointForIndexPath(indexPath).asString())
        
        // Tile is a struct, aka value type, so it gets copied, we could change it to a class
        // type so we can modify values in place very easily
        var tile = tiles[indexPath.row]
        tile.display = tile.data
        tiles[indexPath.row] = tile
        
        
        
        self.collectionView.reloadData()
    }
    
    func pointForIndexPath(indexPath: NSIndexPath) -> Point {
        var row = indexPath.row / self.columnCount
        var column = indexPath.row % self.columnCount
        return Point(x: row, y: column)
    }
    
}

