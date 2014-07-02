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
        var display:String = ""
        var value:String?
        var letter:String?
        var description:String {
            get {
                return String("\(display) \(value) \(uid)")
            }
        }
    }

    let defaultColor = UIColor(red:0.25, green:0.4, blue:0.3, alpha:1.0)
    let names = ["", "Double", "Triple", "DoubleWord", "TripleWord", "TripleWord", "TripleWord", "TripleWord", "TripleWord", "TripleWord" ]
    let letterTileColor = UIColor(red:0.40, green:0.55, blue:0.65, alpha:1.0)
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
                    
                    for character in "AAAAAAAAABBCCDDDDDEEEEEEEEEEEEEFFGGGHHHHIIIIIIIIJKLLLLMMNNNNNOOOOOOOOPPQRRRRRRSSSSSTTTTTTTUUUUVVWWXYYZ__" {
                        letters.append( String(character) )
                    }
                    
                    for segment in 0..control.numberOfSegments {
                        control.setTitle( takeLetter(), forSegmentAtIndex: segment )
                    }
                    
                    control.selectedSegmentIndex = UISegmentedControlNoSegment
                }
                
                if let button = view.viewWithTag(1003) as? UIButton {
                    button.addTarget(self, action:"donePressed", forControlEvents:.TouchUpInside)
                }
            }
        }
    }
    
    init(coder aDecoder: NSCoder!)  {
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            columnCount = 12
            rowCount = 12
        }
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        placeBombs()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell! {
        
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as UICollectionViewCell
        cell.layer.cornerRadius = 8
        cell.backgroundColor = defaultColor
        
        var tile = self.tiles[indexPath.row]
        var background = cell.viewWithTag(1005) as UIImageView
        background.image = nil
        background.alpha = 0.7
        background.transform = CGAffineTransformMakeScale(1.2, 1.2)

        if let value = tile.value?.toInt()? {
            cell.backgroundColor = UIColor.whiteColor()
            
            if value > 0 {
                background.image = UIImage(named:names[value])
            }
        }

        if tile.letter? {
            if tile.display != "" {
                cell.backgroundColor = letterTileColor
            }
        }

        if tile.value == daBomb && tile.letter {
            cell.backgroundColor = UIColor.redColor()
        }
        
        var label = cell.viewWithTag(1001) as UILabel
        label.text = tile.display
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int {
        return self.tiles.count
    }
    
    override func collectionView(collectionView: UICollectionView!, didSelectItemAtIndexPath indexPath: NSIndexPath!) {
        
        var selectedSegmentIndex = letterBar!.selectedSegmentIndex
        if selectedSegmentIndex < 0 {
            println("Tile: \(tiles[indexPath.row])")
            return
        }
        
        var tile = tiles[indexPath.row]
 
        if tile.letter {
            return
        }
        
        if !tile.value {
            updateTile(indexPath)
        }
        
        tile.letter = letterBar!.titleForSegmentAtIndex(selectedSegmentIndex)
        tile.display = String(tile.letter!)
        letterBar!.setTitle("", forSegmentAtIndex: selectedSegmentIndex)
        letterBar!.selectedSegmentIndex = UISegmentedControlNoSegment
        letterBar!.setEnabled(false, forSegmentAtIndex: selectedSegmentIndex)
        
        self.collectionView.reloadData()
    }

    override func collectionView(collectionView: UICollectionView!, viewForSupplementaryElementOfKind kind: String!, atIndexPath indexPath: NSIndexPath!) -> UICollectionReusableView! {
        var result:UICollectionReusableView? = nil
        if kind == UICollectionElementKindSectionFooter {
            
            if !footer {
                footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "LetterBar", forIndexPath: indexPath) as? UICollectionReusableView
                footer!.backgroundColor = UIColor.whiteColor();
                footer!.layer.cornerRadius = 4
                letterBar!.tintColor = letterTileColor;
            }
            
            result = self.footer
        }
        
        return result
    }
    
    func donePressed() {
        
        var bar = letterBar!
        for segment in 0..bar.numberOfSegments {
            if bar.titleForSegmentAtIndex(segment) == "" {
                bar.setTitle( takeLetter(), forSegmentAtIndex: segment )
                bar.setEnabled(true, forSegmentAtIndex: segment)
            }
        }

    }
    
    func takeLetter() -> String {
        var location = Int(arc4random_uniform(UInt32(letters.count)))
        var letter = letters[location]
        letters.removeAtIndex(location)
        return letter
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
            if arc4random_uniform(7) == 0 {
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
                        aroundTiles += tileAtPoint(Point(x:column, y:row))
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

