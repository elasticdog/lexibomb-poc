//
//  ViewController.swift
//  Lexibomb
//
//  Created by Alan Westbrook on 6/29/14.
//  Copyright (c) 2014 Elastic Dog. All rights reserved.
//

import UIKit

let daBomb = "BOMB"

let TileLabelTag = 1001
let TilePointsTag = 1002
let TileImageTag = 1005

let PlayButtonTag = 1003
let PassButtonTag = 1004
let NewGameButtonTag = 1006

let PlayerOneRackTag = 2001
let PlayerTwoRackTag = 2002

let PlayerOneScoreTag = 3001
let PlayerTwoScoreTag = 3002

func + (left: ViewController.Coordinate, right: ViewController.Coordinate) -> ViewController.Coordinate {
    return ViewController.Coordinate(x: left.x + right.x, y: left.y + right.y)
}

func == (left: ViewController.Coordinate, right: ViewController.Coordinate) -> Bool {
    return left.x == right.x &&
        left.y == right.y
}

class ViewController: UICollectionViewController {
    enum Orientation {
        case Horizontal
        case Vertical
    }

    struct Coordinate: CustomStringConvertible, Equatable {
        let x: Int
        let y: Int
        var description: String {
            get {
                return String(format: "(\(x), \(y))")
            }
        }
    }

    class Tile: CustomStringConvertible {
        var uid: Int?
        var bombValue: String?
        var letter: String?
        var description: String {
            get {
                return "\(letter ?? "nil") \(bombValue ?? "nil") \(uid ?? 0)"
            }
        }
    }

    class Player {
        var rack: UISegmentedControl?
        var scoreLabel: UILabel!
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
    var freshGameButton: UIButton!
    var letterBag = [String]()
    var letterPoints = [String: Int]()
    var columnCount = 15
    var rowCount = 15
    var tiles = [Tile]()
    var wordList: NSOrderedSet
    var firstPlay = true

    var playerOne = Player()
    var playerTwo = Player()
    var currentPlayer:Player = Player()

    var footer: UICollectionReusableView? {
        didSet {
            if let view = footer {
                playerOne.rack = view.viewWithTag(PlayerOneRackTag) as? UISegmentedControl
                if let control = playerOne.rack {
                    reset(rack: control)
                    control.selectedSegmentIndex = UISegmentedControlNoSegment
                }
                playerOne.scoreLabel = view.viewWithTag(PlayerOneScoreTag) as? UILabel
                playerOne.scoreLabel.text = "0"

                playerTwo.rack = view.viewWithTag(PlayerTwoRackTag) as? UISegmentedControl
                if let control = playerTwo.rack {
                    reset(rack: control)
                    control.selectedSegmentIndex = UISegmentedControlNoSegment
                }
                playerTwo.scoreLabel = view.viewWithTag(PlayerTwoScoreTag) as? UILabel
                playerTwo.scoreLabel.text = "0"

                playButton = view.viewWithTag(PlayButtonTag) as? UIButton
                if let button = playButton {
                    button.addTarget(self, action: Selector(("playButtonPressed")), for: .touchUpInside)
                }

                passButton = view.viewWithTag(PassButtonTag) as? UIButton
                if let button = passButton {
                    button.addTarget(self, action: Selector(("passButtonPressed")), for: .touchUpInside)
                }
            }
        }
    }

    var header: UICollectionReusableView? {
        didSet {
            if let view = header {
                freshGameButton = view.viewWithTag(NewGameButtonTag) as? UIButton
                if let button = freshGameButton {
                    button.addTarget(self, action: Selector(("freshGameButtonPressed")), for: .touchUpInside)
                }
            }
        }
    }

    func freshGame() {
        tiles = [Tile]()
        letterBag = [String]()
        for character in "AAAAAAAAABBCCDDDDDEEEEEEEEEEEEEFFGGGHHHHIIIIIIIIJKLLLLMMNNNNNOOOOOOOOPPQRRRRRRSSSSSTTTTTTTUUUUVVWWXYYZ__" {
            letterBag.append(String(character))
        }

        if footer != nil {
            reset(rack: playerOne.rack!)
            reset(rack: playerTwo.rack!)

            playerOne.scoreLabel.text = "0"
            playerOne.rack?.isEnabled = true

            playerTwo.scoreLabel.text = "0"
            playerTwo.rack?.isEnabled = false
        }

        placeBombs()
        firstPlay = true
        currentPlayer = playerOne
        currentPlay.removeAll(keepingCapacity: false)
    }

    required init?(coder aDecoder: NSCoder)  {
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


        let bundle = Bundle.main
        let path = bundle.path(forResource: "2of12inf", ofType: "txt")
        let contents = try? String(contentsOfFile: path!)
        wordList = NSOrderedSet(array: contents!.split(separator: "\n"))

        super.init(coder: aDecoder)

        freshGame()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

     var prefersStatusBarHidde:Bool {
        return true
    }

    // MARK: - NSCollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.layer.cornerRadius = 8
        cell.backgroundColor = defaultColor

        let tile = self.tiles[indexPath.row]
        let background = cell.viewWithTag(TileImageTag) as! UIImageView
        background.image = nil
        background.alpha = 0.7
        background.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)

        if let valStr = tile.bombValue, let bombValue = Int(valStr) {
            cell.backgroundColor = UIColor.white

            if bombValue > 0 {
                background.image = UIImage(named: multiplierNames[bombValue])
            }
        }

        if tilePlayed(tile: tile) {
            cell.backgroundColor = letterTileColor
        } else if tile.letter != nil {
            cell.backgroundColor = UIColor.gray
        }

        if tile.bombValue == daBomb && tilePlayed(tile: tile) {
            cell.backgroundColor = UIColor.red
        }

        let label = cell.viewWithTag(TileLabelTag) as! UILabel
        label.text = tile.letter

        let pointsLabel = cell.viewWithTag(TilePointsTag)as! UILabel

        var pointsText = ""
        if let letter = tile.letter {
            pointsText = String(letterPoints[letter]!)
        }

        pointsLabel.text = pointsText

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.tiles.count
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var result: UICollectionReusableView? = nil

        if kind == UICollectionElementKindSectionFooter {
            if footer == nil {
                footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "RackBar", for: indexPath)
                footer!.backgroundColor = UIColor.white;
                footer!.layer.cornerRadius = 1
                playerOne.rack!.tintColor = letterTileColor;
                playerTwo.rack!.tintColor = letterTileColor;
            }
            result = footer
        }
        else if kind == UICollectionElementKindSectionHeader {
            if header == nil {
                header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ControlBar", for: indexPath)
                header!.backgroundColor = UIColor.white;
                header!.layer.cornerRadius = 1
            }
            result = header
        }

        return result!
    }

    // MARK: - NSCollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tile = tiles[indexPath.row]

        if tile.letter != nil {
            if let move = moveForTile(tile: tile) {
                currentPlayer.rack!.setTitle(move.tile.letter, forSegmentAt: move.rackIndex)
                currentPlayer.rack!.selectedSegmentIndex = move.rackIndex
                currentPlayer.rack!.setEnabled(true, forSegmentAt: move.rackIndex)

                tile.letter = nil
                collectionView.reloadData()
                checkPlay()
            }
            return;
        }

        let selectedSegmentIndex = currentPlayer.rack!.selectedSegmentIndex
        if selectedSegmentIndex == UISegmentedControlNoSegment {
            print("Tile: \(tile)")
            return
        }

        tile.letter = currentPlayer.rack!.titleForSegment(at: selectedSegmentIndex)
        currentPlayer.rack!.setTitle("", forSegmentAt: selectedSegmentIndex)
        currentPlayer.rack!.selectedSegmentIndex = UISegmentedControlNoSegment
        currentPlayer.rack!.setEnabled(false, forSegmentAt: selectedSegmentIndex)

        currentPlay.append(Move(tile: tile, rackIndex: selectedSegmentIndex))

        self.collectionView?.reloadData()
        checkPlay()
    }

    // MARK: - UIResponder

    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (motion == UIEventSubtype.motionShake) {
            for index in 0..<self.columnCount * self.rowCount {
                let coordinate = coordinateForIndex(index: index)
                _ = tiles[index]
                updateTileAt(coordinate: coordinate)
            }
        }
        self.collectionView?.reloadData()
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
        let coordinate = coordinateForTile(tile: tile)!

        var adjacentTiles = [Tile]()
        if coordinate.x != 0 {
            if let left = tileAtCoordinate(coordinate: coordinate + Coordinate(x: -1, y: 0)) {
                adjacentTiles.append(left)
            }
        }
        if coordinate.x != columnCount - 1 {
            if let right = tileAtCoordinate(coordinate: coordinate + Coordinate(x: 1, y: 0)) {
                adjacentTiles.append(right)
            }
        }
        if let above = tileAtCoordinate(coordinate: coordinate + Coordinate(x: 0, y: -1)) {
            adjacentTiles.append(above)
        }
        if let below = tileAtCoordinate(coordinate: coordinate + Coordinate(x: 0, y: 1)) {
            adjacentTiles.append(below)
        }

        var adjacent = false
        for tile in adjacentTiles {
            if tile.letter != nil && !tileInCurrentPlay(tile: tile) {
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
            let startingCoordinate = coordinateForTile(tile: currentPlay[0].tile)!

            for move in currentPlay[1..<currentPlay.count] {
                let tileCoordinate = coordinateForTile(tile: move.tile)!

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
        while begin.letter != nil {
            if let previousTile = tileAtCoordinate(coordinate: coordinateForTile(tile: begin)! + decrement) {
                if previousTile.letter == nil {
                    break
                } else {
                    if ((orientation == Orientation.Horizontal) && (coordinateForTile(tile: previousTile)!.x % columnCount == (columnCount - 1))) {
                        break
                    } else {
                        begin = previousTile
                    }
                }
            } else {
                break
            }
        }

        var end = startingTile
        while end.letter != nil {
            if let nextTile = tileAtCoordinate(coordinate: coordinateForTile(tile: end)! + increment) {
                if nextTile.letter == nil {
                    break
                } else {
                    if ((orientation == Orientation.Horizontal) && (coordinateForTile(tile: nextTile)!.x % columnCount == 0)) {
                        break
                    } else {
                        end = nextTile
                    }
                }
            } else {
                break
            }
        }

        var tiles = [Tile]()
        while begin !== end {
            tiles.append(begin)
            begin = tileAtCoordinate(coordinate: coordinateForTile(tile: begin)! + increment)!
        }
        tiles.append(begin)

        return tiles
    }

    func wordContainsAllMoves(word: [Tile]) -> Bool {
        var valid = true
        let currentPlayTiles = currentPlay.map { $0.tile }

        for tile in currentPlayTiles {
            if !word.contains { $0 === tile } {
                valid = false
                break
            }
        }

        return valid
    }

    func tileArrayLexigraphical(tiles: [Tile]) -> Bool {
        return wordLexigraphical(word: tiles.map { $0.letter!.lowercased() }.joined())
    }

    func wordLexigraphical(word: String) -> Bool {
        var lexigraphical = true

        // This doesn't work correctly for more than one blank, I think.
        if let _ = word.index(of: "_") {
            lexigraphical = false

            // ordered by letter frequency for speed
            for character in "etaoinshrdlcumwfgypbvkjxqz" {
                let possible = word.replacingOccurrences(of: "_", with: String(character))

                if wordLexigraphical(word: possible) {
                    lexigraphical = true
                    break
                }
            }
        } else {
            lexigraphical = wordList.contains(word)
        }

        if lexigraphical {
            print("valid spell check: \(word)")
        } else {
            print("INVALID: spell check: \(word)")
        }

        return lexigraphical
    }

    func checkSpelling() -> Bool {
        var valid = true
        var tiles = [Tile]()

        if currentPlay.count == 0 {
            valid = false
        } else if currentPlay.count == 1 {
            tiles = contiguousTiles(startingTile: currentPlay[0].tile, orientation: Orientation.Horizontal)
            if tiles.count > 1 {
                valid = tileArrayLexigraphical(tiles: tiles)
            }

            if valid {
                tiles = contiguousTiles(startingTile: currentPlay[0].tile, orientation: Orientation.Vertical)
                if tiles.count > 1 {
                    valid = tileArrayLexigraphical(tiles: tiles)
                }
            }
        } else if currentPlay.count > 1 {
            if let orientation = currentPlayOrientation {
                tiles = contiguousTiles(startingTile: currentPlay[0].tile,    orientation: orientation)
                if tiles.count > 1 {
                    valid = tileArrayLexigraphical(tiles: tiles)
                }

                if valid {
                    var oppositeOrientation = Orientation.Vertical
                    if orientation == Orientation.Vertical {
                        oppositeOrientation = Orientation.Horizontal
                    }

                    let currentPlayTiles = currentPlay.map { $0.tile }
                    for tile in currentPlayTiles {
                        tiles = contiguousTiles(startingTile: tile, orientation: oppositeOrientation)
                        if tiles.count > 1 {
                            valid = tileArrayLexigraphical(tiles: tiles)
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
                if hasAdjacentTile(tile: move.tile) {
                    valid = true
                    break
                }
            }
            if !valid {
                print("INVALID: no adjacent tiles")
            }
        } else {
            if currentPlay.count == 1 {
                valid = false
                print("INVALID: no single tile words are valid (currentPlay.count == 1)")
            } else {
                valid = true
            }
        }

        if valid {
            // ensure that all of the tiles within currentPlay[] are contained
            // within a single row or a single column
            valid = isCurrentPlayAligned()
            if !valid {
                print("INVALID: unknown axis")
            }
        }

        if valid {
            // grab the contiguous word starting at currentPlay[0] along the currentPlayOrientation
            // and then check that all of the currentPlay[] tiles are contained in it
            if currentPlay.count > 1 {
                let wordTiles = contiguousTiles(startingTile: currentPlay[0].tile, orientation: currentPlayOrientation!)
                valid = wordContainsAllMoves(word: wordTiles)
            }
            if !valid {
                print("INVALID: word does not contain all moves from the rack")
            }
        }

        if valid {
            valid = checkSpelling()
        }

        playButton!.isEnabled = valid
    }

    func scoreTile(tile: Tile) -> (Int, Int) {
        var score = 0
        var multiplier = 1
        let letter = tile.letter!
        let tilePoints = letterPoints[letter]!

        if tilePlayed(tile: tile) {
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

        print("Letter Points: \(tilePoints) Score: \(score) Multiplier: \(multiplier)")
        return (score, multiplier)
    }

    func updateScore(score: Int, multiplier: Int) {
        let total = score * multiplier

        if let previousScore = currentPlayer.scoreLabel.text?.count {
            currentPlayer.scoreLabel.text = "\(total + previousScore)"
        } else {
            currentPlayer.scoreLabel.text = "\(total)"
        }

        print("score: \(score) * \(multiplier) = \(total)")
    }

    func scorePlay() {
        var score = 0
        var playMultiplier = 1

        var word = [Tile]()

        if currentPlay.count == 1 {
            word = contiguousTiles(startingTile: currentPlay[0].tile, orientation: Orientation.Horizontal)
            if word.count > 1 {
                for tile in word {
                    let (letterScore, wordMultiplier) = scoreTile(tile: tile)
                    score += letterScore
                    playMultiplier *= wordMultiplier
                }
                updateScore(score: score, multiplier: playMultiplier)
                score = 0
                playMultiplier = 1
            }

            word = contiguousTiles(startingTile: currentPlay[0].tile, orientation: Orientation.Vertical)
            if word.count > 1 {
                for tile in word {
                    let (letterScore, wordMultiplier) = scoreTile(tile: tile)
                    score += letterScore
                    playMultiplier *= wordMultiplier
                }
                updateScore(score: score, multiplier: playMultiplier)
                score = 0
                playMultiplier = 1
            }
        } else if currentPlay.count > 1 {
            if let orientation = currentPlayOrientation {
                word = contiguousTiles(startingTile: currentPlay[0].tile, orientation: orientation)
                if word.count > 1 {
                    for tile in word {
                        let (letterScore, wordMultiplier) = scoreTile(tile: tile)
                        score += letterScore
                        playMultiplier *= wordMultiplier
                    }
                    updateScore(score: score, multiplier: playMultiplier)
                    score = 0
                    playMultiplier = 1
                }

                var oppositeOrientation = Orientation.Vertical
                if orientation == Orientation.Vertical {
                    oppositeOrientation = Orientation.Horizontal
                }

                let currentPlayTiles = currentPlay.map { $0.tile }
                for tile in currentPlayTiles {
                    word = contiguousTiles(startingTile: tile, orientation: oppositeOrientation)
                    if word.count > 1 {
                        for tile in word {
                            let (letterScore, wordMultiplier) = scoreTile(tile: tile)
                            score += letterScore
                            playMultiplier *= wordMultiplier
                        }
                        updateScore(score: score, multiplier: playMultiplier)
                        score = 0
                        playMultiplier = 1
                    }
                }
            }
        }
    }

    func tilePlayed(tile: Tile) -> Bool {
        var result = false

        if tile.letter != nil {
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
                currentPlay.remove(at: index)
                break
            }
            index += 1
        }

        return result
    }

    func empty(rack: UISegmentedControl) {
        for segment in 0..<rack.numberOfSegments {
            rack.setTitle("", forSegmentAt: segment)
        }
        rack.selectedSegmentIndex = -1
    }

    func fillRack(rack: UISegmentedControl) {
        for segment in 0..<rack.numberOfSegments {
            if rack.titleForSegment(at: segment) == "" {
                if letterBag.count > 0 {
                    rack.setTitle(takeLetter(), forSegmentAt: segment)
                    rack.setEnabled(true, forSegmentAt: segment)
                }
            }
        }
    }

    func reset(rack: UISegmentedControl) {
        empty(rack: rack)
        fillRack(rack: rack)
    }

    func cyclePlay() {
        currentPlay.removeAll()
        collectionView?.reloadData()

        currentPlayer.rack!.selectedSegmentIndex = -1
        currentPlayer.rack!.isEnabled = false

        if currentPlayer === playerOne {
            currentPlayer = playerTwo
        } else {
            currentPlayer = playerOne
        }

        currentPlayOrientation = nil

        currentPlayer.rack!.isEnabled = true

        playButton!.isEnabled = false
    }

    @objc func playButtonPressed() {
        for move in currentPlay {
            updateTileAt(coordinate: coordinateForTile(tile: move.tile)!)
        }

        scorePlay()

        fillRack(rack: currentPlayer.rack!)

        firstPlay = false
        cyclePlay()
    }

    @objc func passButtonPressed() {
        for move in currentPlay {
            currentPlayer.rack!.setTitle(move.tile.letter, forSegmentAt: move.rackIndex)
            currentPlayer.rack!.setEnabled(true, forSegmentAt: move.rackIndex)
            move.tile.letter = nil
        }

        cyclePlay()
    }

    func freshGameButtonPressed() {
        freshGame()
        collectionView?.reloadData()

        currentPlayer.rack!.isEnabled = true
        playButton!.isEnabled = false
    }

    func takeLetter() -> String {
        let location = Int(arc4random_uniform(UInt32(letterBag.count)))

        let letter = letterBag[location]
        letterBag.remove(at: location)

        return letter
    }

    func coordinateForTile(tile: Tile) -> Coordinate? {
        var index = 0

        for checkTile in tiles {
            if let uid = checkTile.uid {
                if let tuid = tile.uid {
                    if uid == tuid {
                        return coordinateForIndex(index: index)
                    }
                }
            }
            index += 1
        }

        return nil
    }

    func coordinateForIndex(index: Int) -> Coordinate {
        let row = index / self.columnCount
        let column = index % self.columnCount

        return Coordinate(x: column, y: row)
    }

    func coordinateForIndexPath(indexPath: NSIndexPath) -> Coordinate {
        return coordinateForIndex(index: indexPath.row)
    }

    func tileAtCoordinate(coordinate: Coordinate) -> Tile? {
        let index = coordinate.y * columnCount + coordinate.x

        if index >= 0 && tiles.count > index {
            return tiles[index]
        } else {
            return nil
        }
    }

    func placeBombs() {
        for index in 0..<columnCount * rowCount {
            let tile = Tile()
            tile.uid = index
            tiles.append( tile )
        }

        var locations = Array( 0 ..< tiles.count )
        
        for _ in 0 ..< bombCount {
            let location = Int(arc4random_uniform(UInt32(locations.count)))
            tiles[location].bombValue = daBomb
            locations.remove(at: location)
        }
    }

    func tilesAroundCoordinate(coordinate: Coordinate) -> [Tile] {
        var neighbors = [Tile]()

        for column in coordinate.x - 1...coordinate.x + 1 {
            if column > -1 && column < columnCount  {
                for row in coordinate.y - 1...coordinate.y + 1 {
                    if row > -1 && row < rowCount && !(column == coordinate.x && row == coordinate.y) {
                        neighbors.append(tileAtCoordinate(coordinate: Coordinate(x: column, y: row))!)
                    }
                }
            }
        }

        return neighbors
    }

    func updateTileAt(coordinate: Coordinate) {
        let tile = tileAtCoordinate(coordinate: coordinate)!

        if tile.bombValue != nil {
            return
        }

        var bombs = 0

        let neighbors = tilesAroundCoordinate(coordinate: coordinate)
        for checkTile in neighbors {
            if checkTile.bombValue == daBomb {
                bombs += 1
            }
        }

        tile.bombValue = String(format: "\(bombs)")

        if bombs == 0 {
            for checkTile in neighbors {
                if checkTile.bombValue != nil {
                    continue
                }
                if let outerCoordinate = coordinateForTile(tile: checkTile) {
                    updateTileAt(coordinate: outerCoordinate)
                }
            }
        }
    }
}
