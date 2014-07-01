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
    }
    

    class Tile : Printable {
        var uid:Int?
        var display:String = "*"
        var value:String?
        var letter:String?
        var description:String {
            get {
                return String("\(display) \(value) \(uid)")
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
                        letters.append( String(character) )
                    }
                    
                    for segment in 0..control.numberOfSegments {
                        control.setTitle( randomLetter(), forSegmentAtIndex: segment )
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
 
        if tile.letter {
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
            tile.letter = letterBar!.titleForSegmentAtIndex(index)
            tile.display = String("\(tile.letter!)/\(tile.value)")
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
    
    func pointForTile(tile:Tile) -> Point? {
        
        var index = 0
        for checkTile in tiles {
            if let uid = checkTile.uid {
                if let tuid = tile.uid {
                    if uid == tuid {
                        return pointForIndex(index)
                    }
                }
            }
            index++
        }
        
        return nil
    }
    
    func pointForIndex(index: Int) -> Point {
        var row = index / self.columnCount
        var column = index % self.columnCount
        return Point(x: column, y: row)
    }
    
    func pointForIndexPath(indexPath: NSIndexPath) -> Point {
        return pointForIndex(indexPath.row)
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

            tile.uid = index
            tiles.append( tile )
        }
    }
    
    func updateTile(indexPath:NSIndexPath) {
        updateTileAt(pointForIndexPath(indexPath))
    }
    
    func tilesAroundPoint(point:Point) -> Array<Tile> {
        var aroundTiles = Array<Tile>()
        for column in point.x - 1...point.x + 1 {
            if column > -1 && column < columnCount  {
                for row in point.y - 1...point.y + 1 {
                    if row > -1 && row < rowCount && !(column == point.x && row == point.y) {
                        var tile = tileAtPoint(Point(x:column, y:row))
                        aroundTiles += tile;
                    }
                }
            }
        }
        
        return aroundTiles
    }
    
    func updateTileAt(point:Point) {
        
        var bombs = 0
        
        var surroundingTiles = tilesAroundPoint(point)
        for checkTile in surroundingTiles {
            if checkTile.value == daBomb {
                bombs++
            }
        }

        var tile = tileAtPoint(point)
        tile.value = String("\(bombs)")
        tile.display = tile.value!
        
        if bombs == 0 {
            for checkTile in surroundingTiles {
                if checkTile.value {
                    continue
                }
                if let outerPoint = pointForTile(checkTile) {
                    updateTileAt(outerPoint)
                }
            }
        }
    }
}

