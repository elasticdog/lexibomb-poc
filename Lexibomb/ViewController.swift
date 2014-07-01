//
//  ViewController.swift
//  Lexibomb
//
//  Created by Alan Westbrook on 6/29/14.
//  Copyright (c) 2014 Elastic Dog. All rights reserved.
//

import UIKit

let daBomb = "💣"

class ViewController: UICollectionViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    struct Point : Printable {
        let x:Int
        let y:Int
        var description:String {
            get {
                return String("(\(x), \(y))")
            }
        }
        func asString() -> String {
            return String("(\(x), \(y))")
        }
    }
    
    class Tile : Printable {
        var display:String = "*"
        var value:String?
        var letter:String?
        var description:String {
            get {
                return String("\(display) \(value)")
            }
        }
    }
    
    var letters = Array<String>()
    var tiles: Tile[] = Array<Tile>()
    var rowCount:Int = 9
    let columnCount: Int = 5
    var letterBar: UISegmentedControl?
    var footer: UICollectionReusableView? {
        didSet {
            if let view = footer {
                letterBar = view.viewWithTag(1002) as? UISegmentedControl
                
                if let control = letterBar {
                    
                    for character in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
                        letters.append(String(character))
                    }
                    
                    for segment in 0..control.numberOfSegments {
                        control.setTitle( randomLetter(), forSegmentAtIndex: segment)
                    }
                }
            }
        }
    }
    
    init(coder aDecoder: NSCoder!)  {
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            columnCount = 12
            rowCount = 17
        }
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        placeBombs()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell! {
        
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as UICollectionViewCell
        
        var tile = self.tiles[indexPath.row]
        
        var label = cell.viewWithTag(1001) as UILabel
        label.text = tile.display
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int {
        return self.tiles.count
    }
    
    override func collectionView(collectionView: UICollectionView!, didSelectItemAtIndexPath indexPath: NSIndexPath!) {
        
        var tile = tiles[indexPath.row]
 
        if tile.display != "*" {
            return
        }
        
        if !tile.value {
            updateTile(indexPath)
        }
        
        if tile.value == daBomb {
            tile.display = tile.value!
        }
        else {
            var index = letterBar!.selectedSegmentIndex
            tile.display = letterBar!.titleForSegmentAtIndex(index)
            letterBar!.setTitle(randomLetter(), forSegmentAtIndex: index)
        }
        
        self.collectionView.reloadData()
    }

    override func collectionView(collectionView: UICollectionView!, viewForSupplementaryElementOfKind kind: String!, atIndexPath indexPath: NSIndexPath!) -> UICollectionReusableView! {
        var result:UICollectionReusableView? = nil;
        if kind == UICollectionElementKindSectionFooter {
            
            if !self.footer {
                self.footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "LetterBar", forIndexPath: indexPath) as? UICollectionReusableView
            }
            
            result = self.footer
        }
        
        return result
    }
    
    func randomLetter() -> String {
        var location = Int(arc4random() % UInt32(letters.count))
        return letters[ location ]
    }
    
    func pointForIndexPath(indexPath: NSIndexPath) -> Point {
        var row = indexPath.row / self.columnCount
        var column = indexPath.row % self.columnCount
        return Point(x: column, y: row)
    }
    
    func tileAtPoint(point:Point) -> Tile {
        return tiles[point.y * columnCount + point.x]
    }
    
    func placeBombs() {
        for index in 0..columnCount * rowCount {
            
            var tile = Tile()
        
            if arc4random() % 7 == 0 {
                tile.value = daBomb
            }

            tiles.append(tile)
        }
        
        println(tiles)
    }
    
    func updateTile(indexPath:NSIndexPath) {
        updateTileAt(pointForIndexPath(indexPath))
    }
    
    func updateTileAt(point:Point) {
        var tile = tileAtPoint(point)
        
        var bombs = 0
        for column in point.x - 1...point.x + 1 {
            
            if column > -1 && column < columnCount  {
                
                for row in point.y - 1...point.y + 1 {
                    
                    if row > -1 && row < rowCount && !(column == point.x && row == point.y) {
                        
                        var point = Point(x:column, y:row)
                        var checkTile = tileAtPoint(point)
                        
                        if checkTile.value == daBomb {
                            bombs++
                        }
                    }
                }
            }
        }
        
        tile.value = String("\(bombs)")
        tile.display = tile.value!
        
        if bombs == 0 {
            for column in point.x - 1...point.x + 1 {
                
                if column > -1 && column < columnCount  {
                    
                    for row in point.y - 1...point.y + 1 {
                        
                        if row > -1 && row < rowCount && !(column == point.x && row == point.y) {
                            var point = Point(x:column, y:row)
                            var tile = tileAtPoint(point)
                            
                            if let value = tile.value {
                                continue
                            }
                            else {
                                updateTileAt(point)
                            }
                        }
                    }
                }
            }
        }
    }
}

