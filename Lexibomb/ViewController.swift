//
//  ViewController.swift
//  Lexibomb
//
//  Created by Alan Westbrook on 6/29/14.
//  Copyright (c) 2014 Elastic Dog. All rights reserved.
//

import UIKit

let daBomb = "💣"

@infix func +(left:ViewController.Point, right:ViewController.Point) -> ViewController.Point {
    return ViewController.Point(x:left.x + right.x, y:left.y + right.y)
}

@infix func ==(left:ViewController.Point, right:ViewController.Point) -> Bool {
    return left.x == right.x &&  left.y == right.y
}

class ViewController: UICollectionViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    enum WordOrientation {
        case Horizontal
        case Vertical
    }
    
    struct Point : Printable, Equatable {
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

    struct Play {
        let tile:Tile
        let barIndex:Int
    }
    
    let columnCount = 6
    let defaultColor = UIColor(red:0.25, green:0.4, blue:0.3, alpha:1.0)
    let letterTileColor = UIColor(red:0.40, green:0.55, blue:0.65, alpha:1.0)
    let names = ["", "Double", "Triple", "DoubleWord", "TripleWord", "TripleWord", "TripleWord", "TripleWord", "TripleWord", "TripleWord" ]

    var bombCount = 10
    var currentWord = Array<Play>()
    var currentWordOrientation:WordOrientation?
    var letterBar: UISegmentedControl?
    var letters = Array<String>()
    var rowCount = 10
    var tiles = Array<Tile>()
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
                    button.addTarget(self, action:"playPressed", forControlEvents:.TouchUpInside)
                }
            }
        }
    }
    
    init(coder aDecoder: NSCoder!)  {
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            columnCount = 15
            rowCount = 15
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

        if tile.value == daBomb && tilePlayed(tile) {
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
        
        var tile = tiles[indexPath.row]

        if tile.letter {
            if let play = takePlayForTile(tile) {
                letterBar!.setTitle(play.tile.letter, forSegmentAtIndex:play.barIndex)
                letterBar!.selectedSegmentIndex = play.barIndex
                letterBar!.setEnabled(true, forSegmentAtIndex: play.barIndex)

                tile.letter = nil
                tile.display = ""
                collectionView.reloadData()
            }
            return;
        }
        
        var selectedSegmentIndex = letterBar!.selectedSegmentIndex
        if selectedSegmentIndex == UISegmentedControlNoSegment {
            println("Tile: \(tile)")
            return
        }
        
        if !checkPlay(tile) {
            return;
        }
        
        tile.letter = letterBar!.titleForSegmentAtIndex(selectedSegmentIndex)
        tile.display = String(tile.letter!)
        letterBar!.setTitle("", forSegmentAtIndex: selectedSegmentIndex)
        letterBar!.selectedSegmentIndex = UISegmentedControlNoSegment
        letterBar!.setEnabled(false, forSegmentAtIndex: selectedSegmentIndex)

        currentWord.append(Play(tile:tile, barIndex:selectedSegmentIndex))
        self.collectionView.reloadData()
    }

    override func collectionView(collectionView: UICollectionView!, viewForSupplementaryElementOfKind kind: String!, atIndexPath indexPath: NSIndexPath!) -> UICollectionReusableView! {
        var result:UICollectionReusableView? = nil
        if kind == UICollectionElementKindSectionFooter {
            
            if !footer {
                footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "LetterBar", forIndexPath: indexPath) as? UICollectionReusableView
                footer!.backgroundColor = UIColor.whiteColor();
                footer!.layer.cornerRadius = 1
                letterBar!.tintColor = letterTileColor;
            }
            
            result = self.footer
        }
        
        return result
    }
    
    func contiguousLettersFrom(tile:Tile, toTile:Tile) -> Bool {
        var contiguous = true
        
        var dx = 0
        var dy = 0
        var originPoint = pointForTile(tile)!
        var destinationPoint = pointForTile(toTile)!
        
        if originPoint.x == destinationPoint.x {
            if originPoint.y < destinationPoint.y {
                dy = 1
            } else {
                dy = -1
            }
        } else if originPoint.y == destinationPoint.y {
            if originPoint.x < destinationPoint.x {
                dx = 1
            } else {
                dx = -1
            }
        } else {
            return false
        }
        
        var iterator = Point(x:dx, y:dy)
        var currentPoint = originPoint + iterator
        while currentPoint != destinationPoint {
            if let currentTile = tileAtPoint(currentPoint) {
                if !currentTile.letter {
                    contiguous = false
                    break
                }
            } else {
                break
            }
            currentPoint = currentPoint + iterator
        }
        
        return contiguous
    }
    
    func checkPlay(tile:Tile) -> Bool {
        var valid = true
        
        if currentWord.count > 0 {
            if currentWord.count == 1 {
                var initialPlay = currentWord[0]
                var referencePoint = pointForTile(initialPlay.tile)!
                var tilePoint = pointForTile(tile)!
                switch (tilePoint.x, tilePoint.y) {
                    case (referencePoint.x + 1, referencePoint.y), (referencePoint.x - 1, referencePoint.y):
                        currentWordOrientation = WordOrientation.Horizontal
                        valid = true
                    
                    case (referencePoint.x, referencePoint.y + 1), (referencePoint.x, referencePoint.y - 1):
                        currentWordOrientation = WordOrientation.Vertical
                        valid = true
                    
                    default:
                        valid = contiguousLettersFrom(initialPlay.tile, toTile:tile)
                    
                        if valid {
                            if referencePoint.y == tilePoint.y {
                                currentWordOrientation = WordOrientation.Horizontal
                            } else {
                                currentWordOrientation = WordOrientation.Vertical
                            }
                        }
                }
            } else {
                var decrement = Point(x:0, y:-1)
                var increment = Point(x:0, y:1)
                if currentWordOrientation! == .Horizontal {
                    decrement = Point(x:-1, y:0)
                    increment = Point(x:1, y:0)
                }
                
                var start = currentWord[0].tile
                while start.letter {
                    if let previous = tileAtPoint(pointForTile(start)! + decrement) {
                        start = previous
                    } else {
                        return false
                    }
                }
                
                var end = currentWord[currentWord.count - 1].tile
                while end.letter {
                    if let next = tileAtPoint(pointForTile(end)! + increment) {
                        end = next
                    } else {
                        return false
                    }
                }
                
                var tilePoint = pointForTile(tile)!
                var startPoint = pointForTile(start)!
                var endPoint = pointForTile(end)!
                switch ( tilePoint ) {
                    case startPoint, endPoint:
                        valid = true

                default:
                        valid = false
                }
            }
        }
        
        return valid
    }
    
    func tilePlayed(tile:Tile) -> Bool {
        var result = false
        
        if tile.letter {
            result = true
            for play in currentWord {
                if play.tile.uid == tile.uid {
                    result = false
                    break
                }
            }
        }
        
        return result
    }

    func takePlayForTile(tile:Tile) -> Play? {
        var result:Play? = nil
        var index = 0

        for play in currentWord {
            if play.tile.uid == tile.uid {
                result = play
                currentWord.removeAtIndex(index)
                break
            }
            index++
        }
        
        return result
    }
    
    func playPressed() {
        
        for play in currentWord {
            updateTileAt(pointForTile(play.tile)!)
        }
        currentWord.removeAll()
        collectionView.reloadData()
        
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
    
    func tileAtPoint(point:Point) -> Tile? {
        var index = point.y * columnCount + point.x
        
        if tiles.count > index {
            return tiles[index]
        } else {
            return nil
        }
    }
    
    func placeBombs() {
        for index in 0..columnCount * rowCount {
            var tile = Tile()
            tile.uid = index
            tiles.append( tile )
        }
        
        for times in 0..bombCount {
            var placed = false
            do {
                var pick = Int(arc4random_uniform(UInt32(tiles.count)))
                var tile = tiles[pick]
            
                if tile.value != daBomb {
                    tile.value = daBomb
                    placed = true
                }
            } while placed != true
        }
    }
    
    func tilesAroundPoint(point:Point) -> Array<Tile> {
        var aroundTiles = Array<Tile>()
        for column in point.x - 1...point.x + 1 {
            if column > -1 && column < columnCount  {
                for row in point.y - 1...point.y + 1 {
                    if row > -1 && row < rowCount && !(column == point.x && row == point.y) {
                        aroundTiles += tileAtPoint(Point(x:column, y:row))!
                    }
                }
            }
        }
        
        return aroundTiles
    }
    
    func updateTileAt(point:Point) {
        
        var tile = tileAtPoint(point)!
        if tile.value {
            return
        }
        
        var bombs = 0
        
        var surroundingTiles = tilesAroundPoint(point)
        for checkTile in surroundingTiles {
            if checkTile.value == daBomb {
                bombs++
            }
        }

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

