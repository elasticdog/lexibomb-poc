//
//  ViewController.swift
//  Lexibomb
//
//  Created by Alan Westbrook on 6/29/14.
//  Copyright (c) 2014 Elastic Dog. All rights reserved.
//

import UIKit

let daBomb = "💣"

let TileLabelTag = 1001
let TilePointsTag = 1002
let TileImageTag = 1005

let PlayButtonTag = 1003
let PassButtonTag = 1004

let PlayerOneRackTag = 2001
let PlayerTwoRackTag = 2002

let PlayerOneScoreTag = 3001
let PlayerTwoScoreTag = 3002

@infix func +(left: ViewController.Coordinate, right: ViewController.Coordinate) -> ViewController.Coordinate {
    return ViewController.Coordinate(x: left.x + right.x, y: left.y + right.y)
}

@infix func ==(left: ViewController.Coordinate, right: ViewController.Coordinate) -> Bool {
    return left.x == right.x && left.y == right.y
}

class ViewController: UICollectionViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    enum Orientation {
        case Horizontal
        case Vertical
    }

    struct Coordinate: Printable, Equatable {
        let x: Int
        let y: Int
        var description: String {
            get {
                return String("(\(x), \(y))")
            }
        }
    }

    class Tile: Printable {
        var uid: Int?
        var bombValue: String?
        var letter: String?
        var description: String {
            get {
                return String("\(letter) \(bombValue) \(uid)")
            }
        }
    }

    class Player {
        var rack: UISegmentedControl?
        var scoreLabel: UILabel!
        init() {
            rack = UISegmentedControl()
            scoreLabel = UILabel()
        }
    }

    struct Move {
        let tile: Tile
        let rackIndex: Int
    }

    let defaultColor = UIColor(red: 0.25, green: 0.4, blue: 0.3, alpha: 1.0)
    let letterTileColor = UIColor(red: 0.40, green: 0.55, blue: 0.65, alpha: 1.0)
    let multiplierNames = ["", "Double", "Triple", "DoubleWord", "TripleWord", "TripleWord", "TripleWord", "TripleWord", "TripleWord", "TripleWord" ]

    var bombCount = 22
    var currentPlay = [Move]()
    var currentPlayOrientation: Orientation?
    var playButton: UIButton!
    var passButton: UIButton!
    var letterBag = [String]()
    var letterPoints = [String: Int]()
    var columnCount = 15
    var rowCount = 15
    var tiles = [Tile]()
    var wordList: NSOrderedSet
    var firstPlay = true

    var playerOne = Player()
    var playerTwo = Player()
    var currentPlayer: Player

    var footer: UICollectionReusableView? {
        didSet {
            if let view = footer {
                playerOne.rack = view.viewWithTag(PlayerOneRackTag) as? UISegmentedControl
                if let control = playerOne.rack {
                    for segment in 0..<control.numberOfSegments {
                        control.setTitle(takeLetter(), forSegmentAtIndex: segment)
                    }
                    control.selectedSegmentIndex = UISegmentedControlNoSegment
                }
                playerOne.scoreLabel = view.viewWithTag(PlayerOneScoreTag) as? UILabel

                playerTwo.rack = view.viewWithTag(PlayerTwoRackTag) as? UISegmentedControl
                if let control = playerTwo.rack {
                    for segment in 0..<control.numberOfSegments {
                        control.setTitle(takeLetter(), forSegmentAtIndex: segment)
                    }
                    control.selectedSegmentIndex = UISegmentedControlNoSegment
                }
                playerTwo.scoreLabel = view.viewWithTag(PlayerTwoScoreTag) as? UILabel

                playButton = view.viewWithTag(PlayButtonTag) as? UIButton
                if let button = playButton {
                    button.addTarget(self, action: "playButtonPressed", forControlEvents: .TouchUpInside)
                }

                passButton = view.viewWithTag(PassButtonTag) as? UIButton
                if let button = passButton {
                    button.addTarget(self, action: "passButtonPressed", forControlEvents: .TouchUpInside)
                }
            }
        }
    }

    init(coder aDecoder: NSCoder!)  {
        for character in "AAAAAAAAABBCCDDDDDEEEEEEEEEEEEEFFGGGHHHHIIIIIIIIJKLLLLMMNNNNNOOOOOOOOPPQRRRRRRSSSSSTTTTTTTUUUUVVWWXYYZ__" {
            letterBag.append(String(character))
        }

        letterPoints = [
            "A": 1,
            "B": 3,
            "C": 3,
            "D": 2,
            "E": 1,
            "F": 4,
            "G": 2,
            "H": 4,
            "I": 1,
            "J": 8,
            "K": 5,
            "L": 1,
            "M": 3,
            "N": 1,
            "O": 1,
            "P": 3,
            "Q": 10,
            "R": 1,
            "S": 1,
            "T": 1,
            "U": 1,
            "V": 4,
            "W": 4,
            "X": 8,
            "Y": 4,
            "Z": 10,
            "_": 0,
        ]

        currentPlayer = playerOne

        let bundle = NSBundle.mainBundle()
        let path = bundle.pathForResource("2of12inf", ofType: "txt")
        let contents = String.stringWithContentsOfFile(path, encoding: NSUTF8StringEncoding, error: nil)
        wordList = NSOrderedSet(array: contents!.componentsSeparatedByString("\n"))

        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        placeBombs()
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    // MARK: - NSCollectionViewDataSource

    override func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell! {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as UICollectionViewCell
        cell.layer.cornerRadius = 8
        cell.backgroundColor = defaultColor

        var tile = self.tiles[indexPath.row]
        var background = cell.viewWithTag(TileImageTag) as UIImageView
        background.image = nil
        background.alpha = 0.7
        background.transform = CGAffineTransformMakeScale(1.2, 1.2)

        if let bombValue = tile.bombValue?.toInt()? {
            cell.backgroundColor = UIColor.whiteColor()

            if bombValue > 0 {
                background.image = UIImage(named: multiplierNames[bombValue])
            }
        }

        if tilePlayed(tile) {
            cell.backgroundColor = letterTileColor
        } else if tile.letter? {
            cell.backgroundColor = UIColor.grayColor()
        }

        if tile.bombValue == daBomb && tilePlayed(tile) {
            cell.backgroundColor = UIColor.redColor()
        }

        var label = cell.viewWithTag(TileLabelTag) as UILabel
        label.text = tile.letter

        var pointsLabel = cell.viewWithTag(TilePointsTag) as UILabel

        var pointsText = ""
        if let letter = tile.letter {
            pointsText = String(letterPoints[letter]!)
        }

        pointsLabel.text = pointsText

        return cell
    }

    override func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int {
        return self.tiles.count
    }

    override func collectionView(collectionView: UICollectionView!, viewForSupplementaryElementOfKind kind: String!, atIndexPath indexPath: NSIndexPath!) -> UICollectionReusableView! {
        var result: UICollectionReusableView? = nil

        if kind == UICollectionElementKindSectionFooter {
            if !footer {
                footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "RackBar", forIndexPath: indexPath) as? UICollectionReusableView
                footer!.backgroundColor = UIColor.whiteColor();
                footer!.layer.cornerRadius = 1
                playerOne.rack!.tintColor = letterTileColor;
                playerTwo.rack!.tintColor = letterTileColor;
            }
            result = self.footer
        }

        return result
    }

    // MARK: - NSCollectionViewDelegate

    override func collectionView(collectionView: UICollectionView!, didSelectItemAtIndexPath indexPath: NSIndexPath!) {
        var tile = tiles[indexPath.row]

        if tile.letter {
            if let move = moveForTile(tile) {
                currentPlayer.rack!.setTitle(move.tile.letter, forSegmentAtIndex: move.rackIndex)
                currentPlayer.rack!.selectedSegmentIndex = move.rackIndex
                currentPlayer.rack!.setEnabled(true, forSegmentAtIndex: move.rackIndex)

                tile.letter = nil
                collectionView.reloadData()
                checkPlay()
            }
            return;
        }

        var selectedSegmentIndex = currentPlayer.rack!.selectedSegmentIndex
        if selectedSegmentIndex == UISegmentedControlNoSegment {
            println("Tile: \(tile)")
            return
        }

        tile.letter = currentPlayer.rack!.titleForSegmentAtIndex(selectedSegmentIndex)
        currentPlayer.rack!.setTitle("", forSegmentAtIndex: selectedSegmentIndex)
        currentPlayer.rack!.selectedSegmentIndex = UISegmentedControlNoSegment
        currentPlayer.rack!.setEnabled(false, forSegmentAtIndex: selectedSegmentIndex)

        currentPlay.append(Move(tile: tile, rackIndex: selectedSegmentIndex))

        self.collectionView.reloadData()
        checkPlay()
    }

    // MARK: - UIResponder

    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent) {
        if (motion == UIEventSubtype.MotionShake) {
            for index in 0..<self.columnCount * self.rowCount {
                var coordinate = coordinateForIndex(index)
                var tile = tiles[index]
                updateTileAt(coordinate)
            }
        }
        self.collectionView.reloadData()
    }

    // MARK: - Private

    func tileInCurrentPlay(tile: Tile) -> Bool {
        var contained = false
        for move in currentPlay {
            if move.tile === tile {
                contained = true
                break
            }
        }
        return contained
    }

    func hasAdjacentTile(tile: Tile) -> Bool {
        let coordinate = coordinateForTile(tile)!

        var adjacentTiles = [Tile]()
        if coordinate.x != 0 {
            if let left = tileAtCoordinate(coordinate + Coordinate(x: -1, y: 0)) {
                adjacentTiles += left
            }
        }
        if coordinate.x != columnCount - 1 {
            if let right = tileAtCoordinate(coordinate + Coordinate(x: 1, y: 0)) {
                adjacentTiles += right
            }
        }
        if let above = tileAtCoordinate(coordinate + Coordinate(x: 0, y: -1)) {
            adjacentTiles += above
        }
        if let below = tileAtCoordinate(coordinate + Coordinate(x: 0, y: 1)) {
            adjacentTiles += below
        }

        var adjacent = false
        for tile in adjacentTiles {
            if tile.letter && !tileInCurrentPlay(tile) {
                adjacent = true
                break
            }
        }

        return adjacent
    }

    func isCurrentPlayAligned() -> Bool {
        var aligned = true

        if currentPlay.count <= 1 {
            currentPlayOrientation = nil
        } else {
            var startingCoordinate = coordinateForTile(currentPlay[0].tile)!

            for move in currentPlay[1..<currentPlay.count] {
                var tileCoordinate = coordinateForTile(move.tile)!

                if let orientation = currentPlayOrientation {
                    if orientation == Orientation.Horizontal {
                        if tileCoordinate.y != startingCoordinate.y {
                            aligned = false
                            currentPlayOrientation = nil
                            break
                        }
                    } else if orientation == Orientation.Vertical {
                        if tileCoordinate.x != startingCoordinate.x {
                            aligned = false
                            currentPlayOrientation = nil
                            break
                        }
                    }
                } else {
                    if tileCoordinate.y == startingCoordinate.y {
                        currentPlayOrientation = Orientation.Horizontal
                    } else if tileCoordinate.x == startingCoordinate.x {
                        currentPlayOrientation = Orientation.Vertical
                    } else {
                        aligned = false
                        break
                    }
                }
            }
        }

        return aligned
    }

    func contiguousTiles(startingTile: Tile, orientation: Orientation) -> [Tile] {
        var decrement = Coordinate(x: -1, y: 0)
        var increment = Coordinate(x: 1, y: 0)

        if orientation == Orientation.Vertical {
            decrement = Coordinate(x: 0, y: -1)
            increment = Coordinate(x: 0, y: 1)
        }

        var begin = startingTile
        while begin.letter {
            if let previousTile = tileAtCoordinate(coordinateForTile(begin)! + decrement) {
                if !previousTile.letter {
                    break
                } else {
                    begin = previousTile
                }
            } else {
                break
            }
        }

        var end = startingTile
        while end.letter {
            if let nextTile = tileAtCoordinate(coordinateForTile(end)! + increment) {
                if !nextTile.letter {
                    break
                } else {
                    end = nextTile
                }
            } else {
                break
            }
        }

        var tiles = [Tile]()
        while begin !== end {
            tiles.append(begin)
            begin = tileAtCoordinate(coordinateForTile(begin)! + increment)!
        }
        tiles.append(begin)

        return tiles
    }

    func wordContainsAllMoves(word: [Tile]) -> Bool {
        var valid = true
        var currentPlayTiles = currentPlay.map { $0.tile }

        for tile in currentPlayTiles {
            if !contains(word, { $0 === tile }) {
                valid = false
                break
            }
        }

        return valid
    }

    func tileArrayLexigraphical(tiles: [Tile]) -> Bool {
        return wordLexigraphical(join("", tiles.map { $0.letter!.lowercaseString }))
    }

    func wordLexigraphical(word: String) -> Bool {
        var lexigraphical = true
        println("spell check: \(word)")

        if let blankRange = word.rangeOfString("_") {
            lexigraphical = false

            // ordered by letter frequency for speed
            for character in "etaoinshrdlcumwfgypbvkjxqz" {
                let possibleWord = word.stringByReplacingCharactersInRange(blankRange, withString: String(character))

                if wordLexigraphical(possibleWord) {
                    lexigraphical = true
                    break
                }
            }
        } else {
            lexigraphical = wordList.containsObject(word)
        }

        return lexigraphical
    }

    func checkSpelling() -> Bool {
        var valid = true
        var tiles = [Tile]()

        if currentPlay.count == 0 {
            valid = false
        } else if currentPlay.count == 1 {
            tiles = contiguousTiles(currentPlay[0].tile, orientation: Orientation.Horizontal)
            if tiles.count > 1 {
                valid = tileArrayLexigraphical(tiles)
            }

            if valid {
                tiles = contiguousTiles(currentPlay[0].tile, orientation: Orientation.Vertical)
                if tiles.count > 1 {
                    valid = tileArrayLexigraphical(tiles)
                }
            }
        } else if currentPlay.count > 1 {
            if let orientation = currentPlayOrientation {
                tiles = contiguousTiles(currentPlay[0].tile, orientation: orientation)
                if tiles.count > 1 {
                    valid = tileArrayLexigraphical(tiles)
                }

                if valid {
                    var oppositeOrientation = Orientation.Vertical
                    if orientation == Orientation.Vertical {
                        oppositeOrientation = Orientation.Horizontal
                    }

                    var currentPlayTiles = currentPlay.map { $0.tile }
                    for tile in currentPlayTiles {
                        tiles = contiguousTiles(tile, orientation: oppositeOrientation)
                        if tiles.count > 1 {
                            valid = tileArrayLexigraphical(tiles)
                            if !valid {
                                break
                            }
                        }
                    }
                }
            }
        } else {
            valid = false
        }

        return valid
    }

    func checkPlay() {
        var valid = false

        if !firstPlay {
            for move in currentPlay {
                if hasAdjacentTile(move.tile) {
                    valid = true
                    break
                }
            }
        } else {
            if currentPlay.count == 1 {
                valid = false
            } else {
                valid = true
            }
        }

        if valid {
            // ensure that all of the tiles within currentPlay[] are contained
            // within a single row or a single column
            valid = isCurrentPlayAligned()
        }

        if valid {
            // grab the contiguous word starting at currentPlay[0] along the currentPlayOrientation
            // and then check that all of the currentPlay[] tiles are contained in it
            if currentPlay.count > 1 {
                var wordTiles = contiguousTiles(currentPlay[0].tile, orientation: currentPlayOrientation!)
                valid = wordContainsAllMoves(wordTiles)
            }
        }

        if valid {
            valid = checkSpelling()
        }

        playButton!.enabled = valid
    }

    func scoreTile(tile: Tile) -> (Int, Int) {
        var score = 0
        var multiplier = 1
        let letter = tile.letter!
        let tilePoints = letterPoints[letter]!

        if tilePlayed(tile) {
            score = tilePoints
        } else {
            switch tile.bombValue! {
            case "0":
                score = tilePoints
            case "1":
                score = tilePoints * 2
            case "2":
                score = tilePoints * 3
            case "3":
                score = tilePoints
                multiplier = 2
            case "4":
                score = tilePoints
                multiplier = 3
            case "5":
                score = tilePoints * 2
                multiplier = 2
            case "6":
                score = tilePoints * 3
                multiplier = 2
            case "7":
                score = tilePoints * 3
            default:
                score = 0
                multiplier = 0
            }
        }

        println("Letter Points: \(tilePoints) Score: \(score) Multiplier: \(multiplier)")
        return (score, multiplier)
    }

    func scorePlay() -> Int {
        var score = 0
        var playMultiplier = 1

        var word = [Tile]()

        if currentPlay.count == 1 {
            word = contiguousTiles(currentPlay[0].tile, orientation: Orientation.Horizontal)
            if word.count > 1 {
                for tile in word {
                    let (letterScore, wordMultiplier) = scoreTile(tile)
                    score += letterScore
                    playMultiplier *= wordMultiplier
                }
            }

            word = contiguousTiles(currentPlay[0].tile, orientation: Orientation.Vertical)
            if word.count > 1 {
                for tile in word {
                    let (letterScore, wordMultiplier) = scoreTile(tile)
                    score += letterScore
                    playMultiplier *= wordMultiplier
                }
            }
        } else if currentPlay.count > 1 {
            if let orientation = currentPlayOrientation {
                word = contiguousTiles(currentPlay[0].tile, orientation: orientation)
                if word.count > 1 {
                    for tile in word {
                        let (letterScore, wordMultiplier) = scoreTile(tile)
                        score += letterScore
                        playMultiplier *= wordMultiplier
                    }
                }

                var oppositeOrientation = Orientation.Vertical
                if orientation == Orientation.Vertical {
                    oppositeOrientation = Orientation.Horizontal
                }

                var currentPlayTiles = currentPlay.map { $0.tile }
                for tile in currentPlayTiles {
                    word = contiguousTiles(tile, orientation: oppositeOrientation)
                    if word.count > 1 {
                        for tile in word {
                            let (letterScore, wordMultiplier) = scoreTile(tile)
                            score += letterScore
                            playMultiplier *= wordMultiplier
                        }
                    }
                }
            }
        }

        println("score: \(score) * \(playMultiplier) = \(score * playMultiplier)")
        score = score * playMultiplier

        return score
    }

    func tilePlayed(tile: Tile) -> Bool {
        var result = false

        if tile.letter {
            result = true
            for move in currentPlay {
                if move.tile.uid == tile.uid {
                    result = false
                    break
                }
            }
        }

        return result
    }

    func moveForTile(tile: Tile) -> Move? {
        var result: Move? = nil
        var index = 0

        for move in currentPlay {
            if move.tile.uid == tile.uid {
                result = move
                currentPlay.removeAtIndex(index)
                break
            }
            index++
        }

        return result
    }

    func playButtonPressed() {
        for move in currentPlay {
            updateTileAt(coordinateForTile(move.tile)!)
        }

        if let previousScore = currentPlayer.scoreLabel.text.toInt() {
            currentPlayer.scoreLabel.text = "\(scorePlay() + previousScore)"
        } else {
            currentPlayer.scoreLabel.text = "\(scorePlay())"
        }

        currentPlay.removeAll()
        collectionView.reloadData()

        var bar = currentPlayer.rack!
        for segment in 0..<bar.numberOfSegments {
            if bar.titleForSegmentAtIndex(segment) == "" {
                if letterBag.count > 0 {
                    bar.setTitle(takeLetter(), forSegmentAtIndex: segment)
                    bar.setEnabled(true, forSegmentAtIndex: segment)
                }
            }
        }

        currentPlayer.rack!.selectedSegmentIndex = -1
        currentPlayer.rack!.enabled = false

        if currentPlayer === playerOne {
            currentPlayer = playerTwo
        } else {
            currentPlayer = playerOne
        }

        currentPlayer.rack!.enabled = true

        firstPlay = false
        playButton!.enabled = false
    }

    func passButtonPressed() {
        for move in currentPlay {
            currentPlayer.rack!.setTitle(move.tile.letter, forSegmentAtIndex: move.rackIndex)
            currentPlayer.rack!.setEnabled(true, forSegmentAtIndex: move.rackIndex)
            move.tile.letter = nil
        }

        currentPlay.removeAll()
        collectionView.reloadData()

        currentPlayer.rack!.selectedSegmentIndex = -1
        currentPlayer.rack!.enabled = false

        if currentPlayer === playerOne {
            currentPlayer = playerTwo
        } else {
            currentPlayer = playerOne
        }

        currentPlayer.rack!.enabled = true

        playButton!.enabled = false
    }

    func takeLetter() -> String {
        var location = Int(arc4random_uniform(UInt32(letterBag.count)))

        var letter = letterBag[location]
        letterBag.removeAtIndex(location)

        return letter
    }

    func coordinateForTile(tile: Tile) -> Coordinate? {
        var index = 0

        for checkTile in tiles {
            if let uid = checkTile.uid {
                if let tuid = tile.uid {
                    if uid == tuid {
                        return coordinateForIndex(index)
                    }
                }
            }
            index++
        }

        return nil
    }

    func coordinateForIndex(index: Int) -> Coordinate {
        var row = index / self.columnCount
        var column = index % self.columnCount

        return Coordinate(x: column, y: row)
    }

    func coordinateForIndexPath(indexPath: NSIndexPath) -> Coordinate {
        return coordinateForIndex(indexPath.row)
    }

    func tileAtCoordinate(coordinate: Coordinate) -> Tile? {
        var index = coordinate.y * columnCount + coordinate.x

        if index >= 0 && tiles.count > index {
            return tiles[index]
        } else {
            return nil
        }
    }

    func placeBombs() {
        for index in 0..<columnCount * rowCount {
            var tile = Tile()
            tile.uid = index
            tiles.append( tile )
        }

        for bomb in 0..<bombCount {
            var placed = false
            do {
                var pick = Int(arc4random_uniform(UInt32(tiles.count)))
                var tile = tiles[pick]

                if tile.bombValue != daBomb {
                    tile.bombValue = daBomb
                    placed = true
                }
            } while placed != true
        }
    }

    func tilesAroundCoordinate(coordinate: Coordinate) -> [Tile] {
        var neighbors = [Tile]()

        for column in coordinate.x - 1...coordinate.x + 1 {
            if column > -1 && column < columnCount  {
                for row in coordinate.y - 1...coordinate.y + 1 {
                    if row > -1 && row < rowCount && !(column == coordinate.x && row == coordinate.y) {
                        neighbors += tileAtCoordinate(Coordinate(x: column, y: row))!
                    }
                }
            }
        }

        return neighbors
    }

    func updateTileAt(coordinate: Coordinate) {
        var tile = tileAtCoordinate(coordinate)!

        if tile.bombValue {
            return
        }

        var bombs = 0

        var neighbors = tilesAroundCoordinate(coordinate)
        for checkTile in neighbors {
            if checkTile.bombValue == daBomb {
                bombs++
            }
        }

        tile.bombValue = String("\(bombs)")

        if bombs == 0 {
            for checkTile in neighbors {
                if checkTile.bombValue {
                    continue
                }
                if let outerCoordinate = coordinateForTile(checkTile) {
                    updateTileAt(outerCoordinate)
                }
            }
        }
    }
}
