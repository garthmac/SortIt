//
//  GameScene.swift
//  SortIt
//
//  Created by iMac 27 on 2015-11-13.
//  Copyright (c) 2015 iMac 27. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, ReplaySceneDelegate, SKPhysicsContactDelegate {
    var replayView: SKView?
    let model = UIDevice.currentDevice().model
    let myLabel = SKLabelNode(fontNamed:"Chalkduster")
    let myLabel2 = SKLabelNode(fontNamed:"Chalkduster")
    let enemy = SKLabelNode(fontNamed:"Arial Bold")
    var plane = SKSpriteNode(imageNamed:"F-15Z1")
    var jetIndex = 0
    var fireButton = SKShapeNode?()
    var fireButton2 = SKShapeNode?()
    let missile = SKEmitterNode(fileNamed: "Explosion")  //(fontNamed:"Arial Bold")
    let missile2 = SKEmitterNode(fileNamed: "Explosion")
    let sky1 = SKEmitterNode(fileNamed: "Fireflies")
    let sky2 = SKEmitterNode(fileNamed: "Magic")
    let sky3 = SKEmitterNode(fileNamed: "Snow")
    var sky = [SKEmitterNode]()
    var skyIndex = 0
    var isFired = false
    var isFired2 = false
    //Set up Physicsbody bit masks
    let enemyCategory : UInt32 = 0b001
    let planeCategory : UInt32 = 0b010
    let spriteCategory : UInt32 = 0b100
    let sound0 = SKAction.playSoundFileNamed("16.7 Million Particles on an iPad Pro.mp3", waitForCompletion: true)
    let sound1 = SKAction.playSoundFileNamed("beep5.mp3", waitForCompletion: false)
    let sound2 = SKAction.playSoundFileNamed("beep10.mp3", waitForCompletion: false)
    let sound3 = SKAction.playSoundFileNamed("aircraft013.mp3", waitForCompletion: false)
    let sound4 = SKAction.playSoundFileNamed("aircraft036.mp3", waitForCompletion: false)
    let sound5 = SKAction.playSoundFileNamed("aircraft064.mp3", waitForCompletion: false)
    var soundOn = true
    var launchedSprites = 0
    var lostSprites = 0
    var planeDamage = 0
    var score = 0  //number of captured Bogeys
    struct Constants {
        static let FlameOffset = CGFloat(420.0)
        static let Scale = CGFloat(0.15)
        static let SquadronSize = 12
        static let Top = CGFloat(100.0)
    }
    func flyBy () {
        let sprite = SKSpriteNode.next(jetIndex)
        sprite.xScale = scaleFactor
        sprite.position = CGPoint(x: frame.width/2, y: -frame.height/4)
        addFlames(sprite)
        let action = SKAction.moveToY(frame.height*2, duration: 12)
        sprite.runAction(action, completion: { [weak self] (success) -> Void in
            sprite.removeFromParent()
            self!.plane.xScale = self!.scaleFactor
            self!.plane.position = CGPoint(x: self!.frame.width/2, y: self!.frame.height*0.5)
            let action = SKAction.scaleBy(Constants.Scale , duration: 5)  //resizeByWidth(-self!.plane.size.width/2, height: -self!.plane.size.height/2, duration: 5)
            self!.plane.runAction(action, completion: { [weak self] (success) -> Void in
                self!.resetPlane()
                })
            })
        addFlames(plane)
        plane.physicsBody = SKPhysicsBody(circleOfRadius: enemy.frame.size.width/2)
        plane.physicsBody!.dynamic = false  //added
        plane.physicsBody!.restitution = 1.0
        plane.physicsBody!.linearDamping = 0.0
        //plane.physicsBody!.applyImpulse(CGVector(dx: 2, dy: 2))
        plane.physicsBody!.categoryBitMask = planeCategory
        plane.physicsBody!.collisionBitMask = enemyCategory
        plane.physicsBody!.contactTestBitMask = enemyCategory
    }
    func flameOffset(jet: Int) -> CGFloat {
        switch jet {
        case 0: return Constants.FlameOffset - 10
        case 1: return Constants.FlameOffset + 45
        case 2: return Constants.FlameOffset - 15
        case 3: return Constants.FlameOffset + 85
        case 4: return Constants.FlameOffset + 70
        case 5: return Constants.FlameOffset + 55
        default: return Constants.FlameOffset
        }
    }
    func addFlames(spriteOrPlane: SKSpriteNode) {
        let fire = SKEmitterNode(fileNamed: "Fire")
        if jetIndex > 4 {
            fire!.position = CGPoint(x: 0, y: flameOffset(jetIndex)-frame.height)
            spriteOrPlane.addChild(fire!)
            fire!.zRotation = CGFloat(M_PI)
            addChild(spriteOrPlane)
        } else {
            fire!.position = CGPoint(x: -25, y: flameOffset(jetIndex)-frame.height)
            spriteOrPlane.addChild(fire!)
            fire!.zRotation = CGFloat(M_PI)
            let fire2 = SKEmitterNode(fileNamed: "Fire")
            fire2!.position = CGPoint(x: 25, y: flameOffset(jetIndex)-frame.height)
            spriteOrPlane.addChild(fire2!)
            fire2!.zRotation = CGFloat(M_PI)
            addChild(spriteOrPlane)
        }
    }
    func replaySceneDidFinish(myScene: ReplayScene, command: String) {
        myScene.view!.removeFromSuperview()
        if (command=="Restart") {
            for idx in 0..<sky.count {
                if idx == skyIndex {
                    sky[idx].numParticlesToEmit = 1
                }
            }
            jetIndex += 1
            plane.removeFromParent()
            plane = SKSpriteNode.next(jetIndex)
            skyIndex = Int(arc4random() % 3)
            sky[skyIndex].numParticlesToEmit = 0
            sky[skyIndex].position = CGPoint(x: frame.width/2, y: frame.height)
            enemy.position = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
            enemy.physicsBody!.applyImpulse(CGVectorMake(3, 3))
            missile!.hidden = true
            missile!.position = self.plane.position
            isFired = false
            missile2!.hidden = true
            missile2!.position = self.plane.position
            isFired2 = false
            launchedSprites = 0
            lostSprites = 0
            planeDamage = 0
            score = 0
            myLabel.fontColor = UIColor.greenColor()
            updateScoreBoard()
            for (_,sprite) in spriteNodeDict {
                sprite.removeFromParent()
            }
            addSquadron()
            flyBy()
        } else {
            let delay = Double(2) * Double(NSEC_PER_SEC)
            let totalTime = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), Int64(delay))
            dispatch_after(totalTime, dispatch_get_main_queue()) { [weak self] (success) -> Void in
                self!.goToEndgame()
            }
        }
    }
    var scaleFactor = CGFloat(1.0)
    var spriteNodeDict = [Int:SKSpriteNode]()
    func addSquadron() {
        var idx = 0
        for _ in 0..<Constants.SquadronSize {
            let sprite = SKSpriteNode.next(jetIndex)
            launchedSprites++
            spriteNodeDict[idx] = sprite
            updateScoreBoard()
            let scale = max(CGFloat.random(12.0)/100.0, 0.08)
            sprite.xScale = scale*scaleFactor
            sprite.yScale = scale
            sprite.position = CGPoint (x: CGFloat.random(frame.maxX), y: CGFloat.random(frame.maxY))
            let fire = SKEmitterNode(fileNamed: "Fire")
            fire!.position = CGPoint(x: 0, y: flameOffset(jetIndex)-frame.height)
            sprite.addChild(fire!)
            fire!.zRotation = CGFloat(M_PI)
            sprite.physicsBody = SKPhysicsBody(circleOfRadius: enemy.frame.size.width/2)
            sprite.physicsBody!.dynamic = true  //added
            sprite.physicsBody!.restitution = 1.0
            sprite.physicsBody!.linearDamping = 0.0
            sprite.physicsBody!.applyImpulse(CGVector(dx: 2, dy: 2))
            sprite.physicsBody!.categoryBitMask = spriteCategory
            sprite.physicsBody!.collisionBitMask = enemyCategory
            sprite.physicsBody!.contactTestBitMask = enemyCategory
            addChild(sprite)
            idx += 1
        }
    }
    override func didMoveToView(view: SKView) {
        /* Setup your REPLAY scene here */
        var replayAdjustment = CGFloat(4)
        if model.hasPrefix("iPad") {
            replayAdjustment = 2.5  //was 2
        } else {
            scaleFactor = 0.64
        }
        replayView = SKView(frame: CGRect(x: frame.size.width/(replayAdjustment*2), y: frame.size.height/(replayAdjustment*2), width: frame.size.width/replayAdjustment, height: frame.size.height/replayAdjustment))
        let replayScene = ReplayScene(size: CGSize(width: self.frame.size.width/replayAdjustment, height: self.frame.size.height/replayAdjustment))
        self.replayView!.presentScene(replayScene)
        replayScene.thisDelegate = self
        
        /* Setup your GAME scene here */
        self.scaleMode = .Fill
        self.backgroundColor = UIColor.blackColor()
        runAction(SKAction.repeatActionForever(sound0))
        sky = [sky1!, sky2!, sky3!]
        skyIndex = Int(arc4random() % 3)
        sky[skyIndex].position = CGPoint(x: frame.width/2, y: frame.height)
        for idx in 0..<sky.count {
            addChild(sky[idx])
            if idx != skyIndex {
                sky[idx].numParticlesToEmit = 1
            }
        }
        myLabel.fontColor = UIColor.blueColor()
        myLabel2.fontColor = UIColor.purpleColor()
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector.zero
        myLabel.text = "Guided Missile"
        myLabel.fontSize = 30
        myLabel.position = CGPoint(x: CGRectGetMidX(frame), y: (CGRectGetMaxY(frame)-Constants.Top))
        addChild(myLabel)
        myLabel2.position = CGPoint.addPoint(myLabel.position, right: CGPoint(x: 0, y: -50))
        myLabel2.fontSize = 30
        addChild(myLabel2)
        physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)  //wall
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsBody!.friction = 0
//        physicsBody!.categoryBitMask = wallCategory
//        physicsBody!.collisionBitMask = enemyCategory
//        physicsBody!.contactTestBitMask = enemyCategory
        
        enemy.text = "o"
        enemy.fontSize = 20
        enemy.fontColor = UIColor.yellowColor()
        enemy.position = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
        addChild(enemy)
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.frame.size.width/2)
        enemy.physicsBody!.restitution = 1.0
        enemy.physicsBody!.linearDamping = 0.0
        enemy.physicsBody!.applyImpulse(CGVector(dx: 3, dy: 3))
        enemy.physicsBody!.categoryBitMask = enemyCategory
        enemy.physicsBody!.collisionBitMask = spriteCategory
        enemy.physicsBody!.contactTestBitMask = spriteCategory
        
        let fireText = SKLabelNode(fontNamed:"Arial Bold")
        fireText.text = "Fire"
        fireText.fontSize = 10
        fireButton = SKShapeNode(circleOfRadius: fireText.frame.width)
        fireButton!.fillColor = SKColor.redColor()
        fireButton!.name = "fireButton"
        fireButton!.addChild(fireText)
        addChild(fireButton!)
        let fireText2 = SKLabelNode(fontNamed:"Arial Bold")
        fireText2.text = "Fire"
        fireText2.fontSize = 10
        fireButton2 = SKShapeNode(circleOfRadius: fireText2.frame.width)
        fireButton2!.fillColor = SKColor.blueColor()
        fireButton2!.name = "fireButton2"
        fireButton2!.addChild(fireText2)
        addChild(fireButton2!)
        
        addSquadron()
        flyBy()
        
//        missile.text = "."
//        missile.fontSize = 60
        missile!.hidden = true
        missile2!.hidden = true
        addChild(missile!)
        addChild(missile2!)
    }
    func resetFireButtons() {
        fireButton!.position = CGPoint(x: plane.position.x+90, y: plane.position.y+15)  //put it off the wing edge
        fireButton2!.position = CGPoint(x: plane.position.x-90, y: plane.position.y+15)  //put it off the wing edge
    }
    func resetPlane() {
        plane.xScale = Constants.Scale * scaleFactor
        plane.yScale = Constants.Scale
        plane.position = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
        resetFireButtons()
    }
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch: AnyObject in touches {
            let touchLocation = touch.locationInNode(self)
            let previousLocation = touch.previousLocationInNode(self)
            var planeX = plane.position.x + (touchLocation.x - previousLocation.x)
            var planeY = plane.position.y + (touchLocation.y - previousLocation.y)
            if planeX > size.width {planeX = size.width}
            if planeX < 0 {planeX = 0}
            if planeY > size.height {planeY = size.height}
            if planeY < 0 {planeY = 0}
            plane.position = CGPoint(x: planeX, y: planeY)
            resetFireButtons()
        }
    }

    //You wan to define collision categories so that each kind of body in your game uses its own bit in the mask. (You've got a good idea using Swift's binary literal notation, but you're defining categories that overlap.) Here's an example of non-overlapping categories:
    enum PhysicsCategory : UInt32 {
        case None   = 0
        case All    = 0xFFFFFFFF
        case Enemy  = 0b001
        case Plane  = 0b010
        case Sprite = 0b100
    }
    //Testing & Tracking Categories  I like to use a two-tiered approach to contact handlers. First, I check for the kind of collision — is it a wall/enemy collision or a wall/sprite collision or a sprite/enemy collision? Then, if necessary I check to see which body in the collision is which. This doesn't cost much in terms of computation, and it makes it very clear at every point in my code what's going on.
    func didBeginContact(contact: SKPhysicsContact) {
        // Step 1. Bitiwse OR the bodies' categories to find out what kind of contact we have
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        switch contactMask {
        case PhysicsCategory.Sprite.rawValue | PhysicsCategory.Enemy.rawValue:
            // Step 2. Disambiguate the bodies in the contact
            if contact.bodyA.categoryBitMask == PhysicsCategory.Enemy.rawValue {
                handleCollision(contact.bodyA.node as! SKLabelNode,
                    sprite: contact.bodyB.node as! SKSpriteNode)
            } else {
                handleCollision(contact.bodyB.node as! SKLabelNode,
                    sprite: contact.bodyA.node as! SKSpriteNode)
            }
        case PhysicsCategory.Plane.rawValue | PhysicsCategory.Enemy.rawValue:
            print("plane + enemy")
            if contact.bodyA.categoryBitMask == PhysicsCategory.Plane.rawValue {
                handleCollision(contact.bodyA.node as! SKSpriteNode,
                    enemy: contact.bodyB.node as! SKLabelNode)
            } else {
                handleCollision(contact.bodyB.node as! SKSpriteNode,
                    enemy: contact.bodyA.node as! SKLabelNode)
            }
//        case PhysicsCategory.Wall.rawValue | PhysicsCategory.Sprite.rawValue:
//            print("wall + sprite")
            // Maybe we don't even care about wall/sprite collision?
            // I just put this here for completeness, but you can omit it
            // or set up contactTestBitMask to ignore it entirely
        default: break
            // Nobody expects this, so satisfy the compiler and catch
            // ourselves if we do something we didn't plan to
            //fatalError("other collision: \(contactMask)")
        }
    }
    func handleCollision(enemy: SKLabelNode, sprite: SKSpriteNode) {
        if !sprite.hasActions() {
            lostSprites++
        }
        let fire = SKEmitterNode(fileNamed: "Fire")
        sprite.addChild(fire!)
        sprite.runAction(SKAction.colorizeWithColor(UIColor.random, colorBlendFactor: 1.0, duration: 3))
        updateScoreBoard()
        if lostSprites % 2 == 0 {
            destroySprite(sprite, crashSound: sound4)
        } else {
            destroySprite(sprite, crashSound: sound3)
        }
    }
    func destroySprite(sprite: SKSpriteNode, crashSound: SKAction) {
        sprite.runAction(crashSound, completion: { (success) -> Void in
            sprite.runAction(SKAction.fadeAlphaTo(0, duration: 5))
            let delay = Double(5) * Double(NSEC_PER_SEC)
            let totalTime = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), Int64(delay))
            dispatch_after(totalTime, dispatch_get_main_queue()) { [weak self] (success) -> Void in
                sprite.removeFromParent()
                if self!.lostSprites == Constants.SquadronSize {
                    self!.replay()
                }
            }
        })
    }
    func handleCollision(plane: SKSpriteNode, enemy: SKLabelNode) {
        planeDidCollideWithEnemy(plane, enemy: enemy)
        let dx = (enemy.position.x - plane.position.x)*(-10)
        let dy = (enemy.position.y - plane.position.y)*(-10)
        let action = SKAction.moveBy(CGVector(dx: dx, dy: dy), duration: 2)  //rotateByAngle(CGFloat(2*M_PI), duration:2)
        plane.runAction(action, completion: { [weak self] (success) -> Void in
            self!.resetFireButtons()
        })
    }
    func goToEndgame() {
        exit(0)
    }
    func planeDidCollideWithEnemy(plane: SKSpriteNode, enemy: SKLabelNode) {
        planeDamage++
        let action = SKAction.rotateByAngle(CGFloat(2*M_PI), duration: 2)
        plane.runAction(action)
        captureBogey(0)
        updateScoreBoard()
        if planeDamage == 3 {  //end of level
            replay()
        }
    }
    func replay() {
        let action = SKAction.moveToY(Constants.Top/2, duration: 0.5)
        enemy.runAction(action, completion: { [weak self] (success) -> Void in
            self!.view!.addSubview(self!.replayView!)
            self!.isFired = false
            self!.isFired2 = false
            })
    }
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       /* Called when a touch begins */
        for touch in touches {
            if touch.tapCount == 1 {
                let location = touch.locationInNode(self)
                let thisNode = nodeAtPoint(location)
                if (thisNode.name != nil) {
                    if (thisNode.name == fireButton?.name) {
                        isFired = true
                        soundOn = true
                        runAction(sound5)
                        missile!.position = plane.position
                        missile!.hidden = false
                    } else if (thisNode.name == fireButton2?.name) {
                        isFired2 = true
                        soundOn = true
                        runAction(sound5)
                        missile2!.position = plane.position
                        missile2!.hidden = false
                    }
                }
            } else if touch.tapCount == 2 {
                resetMissile()
            }
        }
    }
    func resetMissile() {
        let delay = Double(2) * Double(NSEC_PER_SEC)
        let totalTime = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), Int64(delay))
        dispatch_after(totalTime, dispatch_get_main_queue()) { [weak self] (success) -> Void in
            self!.missile!.hidden = true
            self!.missile2!.hidden = true
            self!.isFired = false
            self!.isFired2 = false
            self!.missile!.position = self!.plane.position
            self!.missile2!.position = self!.plane.position
            self!.enemy.physicsBody!.applyImpulse(CGVector(dx: 3, dy: 3))
            self!.runAction(self!.sound1)
        }
    }
    func resetSound() {
        soundOn = false
    }
    func updateScoreBoard() {
        if planeDamage == 3 {
            myLabel.fontColor = UIColor.redColor()
            myLabel.text = "Game Over!  Captured Bogeys: \(score), Sprites Lost: \(lostSprites)"
            myLabel2.text = "Missile Hits: \(score), Sprites Launched: \(launchedSprites)"
        } else {
            myLabel.text = "Missile Hits: \(score), Sprites Launched: \(launchedSprites)"
            myLabel2.text = "Plane damage: \(planeDamage), Sprites Lost: \(lostSprites)"
        }
    }
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        let blastRadius = 25
        let missileSpeed: CGFloat = 50
        if isFired {
            let dX = (enemy.position.x - missile!.position.x)
            let dY = (enemy.position.y - missile!.position.y)
            let action = SKAction.moveBy(CGVector(dx: dX*missileSpeed/2500, dy: dY*missileSpeed/2500), duration: 1.0)
            missile!.runAction(action)
            if (Int(abs(dX)) < blastRadius) && (Int(abs(dY)) < blastRadius) {
                captureBogey(1)
            }
        }
        if isFired2 {
            let dX2 = (enemy.position.x - missile2!.position.x)
            let dY2 = (enemy.position.y - missile2!.position.y)
            let action2 = SKAction.moveBy(CGVector(dx: dX2*missileSpeed/2500, dy: dY2*missileSpeed/2500), duration: 1.0)
            missile2!.runAction(action2)
            if (Int(abs(dX2)) < blastRadius) && (Int(abs(dY2)) < blastRadius) {
                captureBogey(2)
            }
        }
    }
    func captureBogey(shot: Int) {
        if soundOn {
            runAction(sound2)
            score++
            updateScoreBoard()
            resetMissile()
        }
        if shot < 2 {
            missile!.position = enemy.position
            let action = SKAction.moveToY(Constants.Top/2, duration: 0.5)
            enemy.physicsBody!.velocity = CGVector(dx: 0,dy: 0)
            enemy.runAction(action)
            missile!.runAction(action)
            resetSound()
        } else if shot == 2 {
            missile2!.position = enemy.position
            let action = SKAction.moveToY(Constants.Top/2, duration: 0.5)
            enemy.physicsBody!.velocity = CGVector(dx: 0,dy: 0)
            enemy.runAction(action)
            missile2!.runAction(action)
            resetSound()
        }
    }
}

private extension CGFloat {
    static func random(max: CGFloat) -> CGFloat {
        return CGFloat(arc4random() % UInt32(Int(max)))
    }
}
private extension CGPoint {
    static func addPoint(left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
}
private extension SKSpriteNode {
    class var random: SKSpriteNode {
        switch arc4random() % 6 {
        case 0: return SKSpriteNode(imageNamed:"F-15Z1")
        case 1: return SKSpriteNode(imageNamed:"MiG-29Z")
        case 2: return SKSpriteNode(imageNamed:"Su-33")
        case 3: return SKSpriteNode(imageNamed:"F1444842379440")
        case 4: return SKSpriteNode(imageNamed:"F-104 Starfighter")
        case 5: return SKSpriteNode(imageNamed:"F-35A")
        default: return SKSpriteNode(imageNamed:"F-15Z1")
        }
    }
    static func next(index: Int) -> SKSpriteNode {
        switch index {
        case 0: return SKSpriteNode(imageNamed:"F-15Z1")
        case 1: return SKSpriteNode(imageNamed:"MiG-29Z")
        case 2: return SKSpriteNode(imageNamed:"Su-33")
        case 3: return SKSpriteNode(imageNamed:"F1444842379440")
        case 4: return SKSpriteNode(imageNamed:"F-104 Starfighter")
        case 5: return SKSpriteNode(imageNamed:"F-35A")
        default: return SKSpriteNode(imageNamed:"F-15Z1")
        }
    }
}
private extension UIColor {
    class var random: UIColor {
        switch arc4random() % 8 {
        case 0: return UIColor.greenColor()
        case 1: return UIColor.blueColor()
        case 2: return UIColor.orangeColor()
        case 3: return UIColor.redColor().colorWithAlphaComponent(0.5)
        case 4: return UIColor.purpleColor()
        case 5: return UIColor.yellowColor()
        case 6: return UIColor.brownColor()
        case 7: return UIColor.darkGrayColor()
        default: return UIColor.redColor()
        }
    }
}
