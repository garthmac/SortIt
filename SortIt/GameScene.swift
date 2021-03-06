//
//  GameScene.swift
//  SortIt
//
//  Created by iMac 27 on 2015-11-13.
//  Copyright (c) 2015 iMac 27. All rights reserved.
//

import SpriteKit
import GameKit

class GameScene: SKScene, ReplaySceneDelegate, SKPhysicsContactDelegate, GKGameCenterControllerDelegate {
    var replayView: SKView?
    var replayScene: ReplayScene?
    let model = UIDevice.currentDevice().model
    let myLabel = SKLabelNode(fontNamed:"Chalkduster")
    let myLabel2 = SKLabelNode(fontNamed:"Chalkduster")
    let myLabel3 = SKLabelNode(fontNamed:"Chalkduster")
    // MARK: - SKNodes
    let enemy = SKLabelNode(fontNamed:"Arial Bold")
    let laser = SKSpriteNode(imageNamed: "laserbeam_blueVerticle")
    var plane = SKSpriteNode(imageNamed:"F-15Z1")
    var jetIndex = 0
    var fireButton = SKShapeNode?()
    var fireButton2 = SKShapeNode?()
    let fireText = SKLabelNode(fontNamed:"Arial Bold")
    let fireText2 = SKLabelNode(fontNamed:"Arial Bold")
    // MARK: - SKEmitterNodes
    let missile = SKEmitterNode(fileNamed: "Explosion")  //(fontNamed:"Arial Bold")
    let missile2 = SKEmitterNode(fileNamed: "Explosion")
    let sky1 = SKEmitterNode(fileNamed: "Fireflies")
    let sky2 = SKEmitterNode(fileNamed: "Magic")
    let sky3 = SKEmitterNode(fileNamed: "Snow")
    let smoke = SKEmitterNode(fileNamed: "Smoke")
    let halo = SKEmitterNode(fileNamed: "Halo")
    var smokeIndex: Int? = nil
    var spriteNodes = [SKSpriteNode]()
    var sky = [SKEmitterNode]()
    var skyIndex = 0
    var isFired = false
    var isFired2 = false
    // MARK: - SkActions - sounds
    let sound0 = SKAction.playSoundFileNamed("16.7 Million Particles on an iPad Pro.mp3", waitForCompletion: true)
    let sound1 = SKAction.playSoundFileNamed("beep5.mp3", waitForCompletion: false)
    let sound2 = SKAction.playSoundFileNamed("beep10.mp3", waitForCompletion: false)
    let sound3 = SKAction.playSoundFileNamed("aircraft013.mp3", waitForCompletion: false)
    let sound4 = SKAction.playSoundFileNamed("aircraft036.mp3", waitForCompletion: false)
    let sound5 = SKAction.playSoundFileNamed("aircraft064.mp3", waitForCompletion: false)
    let sound6 = SKAction.playSoundFileNamed("laser1.mp3", waitForCompletion: false)
    let sound7 = SKAction.playSoundFileNamed("laser3.mp3", waitForCompletion: false)
    var soundOn = true
    var launchedSprites = 0
    var lostSprites = 0
    var planeDamage = 0
    var missileHits = 0  //number of captured Bogeys
    var scaleFactor = CGFloat(1.0)
    private var autoStartTimer: NSTimer?
    var missilesFired = 0
    var aces = 0
    var bulletsFired = 0
    var score = 0
    // MARK: - Physicsbody bit masks
    let enemyCategory:  UInt32 = 0b0001
    let planeCategory:  UInt32 = 0b0010
    let spriteCategory: UInt32 = 0b0100
    let shellCategory:  UInt32 = 0b1000
    struct Constants {
        static let CannonSize = 6
        static let EngineOffset = CGFloat(25)
        static let FlameOffset = CGFloat(420.0)
        static let Scale = CGFloat(0.25)
        static let SquadronSize = 12
        static let Top = CGFloat(50.0)
        static let VerticlePosition = CGFloat(0.15)
    }
    // MARK: - flyBy()
    func flyBy() {
        let sprite = SKSpriteNode.next(jetIndex)  //plane standin double for flyBy
        sprite.yScale = 1.0 / scaleFactor
        sprite.position = CGPoint(x: frame.width/2, y: -frame.height*0.6)
        addFlames(sprite)
        
        plane.xScale = scaleFactor/2
        plane.yScale = 0.5
        let eitherSide = Int(arc4random() % 2) == 0
        if eitherSide {
            plane.position.x = frame.width
        }
        var planeSequence = [SKAction]()
        let action1 = SKAction.moveTo(CGPoint(x: frame.width/2, y: frame.height*Constants.VerticlePosition*3), duration: 2)
        planeSequence.append(action1)
        let action2 = SKAction.scaleBy(Constants.Scale*2 , duration: 1)  //*2 becuse made 1/2 scale at beginning of flyBy()
        planeSequence.append(action2)
        let action3 = SKAction.moveTo(CGPoint(x: frame.width/2, y: frame.height*Constants.VerticlePosition), duration: 2)
        planeSequence.append(action3)
        let action = SKAction.moveToY(frame.height*1.6, duration: 6)
        sprite.runAction(action, completion: { [weak self] (success) -> Void in
            sprite.removeFromParent()
            //after dummy sprite flys by, animate actual plane
            self!.plane.runAction(SKAction.sequence(planeSequence), completion: { [weak self] (success) -> Void in
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
        switch jet % 14 {
        case 0: return Constants.FlameOffset - 10
        case 1: return Constants.FlameOffset + 50
        case 2: return Constants.FlameOffset - 15
        case 3: return Constants.FlameOffset + 80
        case 4: return Constants.FlameOffset - 65
        case 5: return Constants.FlameOffset - 10
        case 6: return Constants.FlameOffset + 35
        case 7: return Constants.FlameOffset + 20
        case 8: return Constants.FlameOffset + 50
        case 9: return Constants.FlameOffset - 10
        case 10: return Constants.FlameOffset + 55
        case 11: return Constants.FlameOffset
        case 12: return Constants.FlameOffset + 130
        case 13: return Constants.FlameOffset + 55
        default: return Constants.FlameOffset + 55
        }
    }
    func addFlames(spriteOrPlane: SKSpriteNode) {
        let fire = SKEmitterNode(fileNamed: "Fire")
        if jetIndex > 9 {
            fire!.position = CGPoint(x: 0, y: flameOffset(jetIndex)-frame.height)
            fire!.zRotation = CGFloat(M_PI)
            addChild(spriteOrPlane)
            spriteOrPlane.addChild(fire!)
        } else {
            fire!.position = CGPoint(x: Constants.EngineOffset, y: flameOffset(jetIndex)-frame.height)
            fire!.zRotation = CGFloat(M_PI)
            let fire2 = SKEmitterNode(fileNamed: "Fire")
            fire2!.position = CGPoint(x: -Constants.EngineOffset, y: flameOffset(jetIndex)-frame.height)
            fire2!.zRotation = CGFloat(M_PI)
            addChild(spriteOrPlane)
            spriteOrPlane.addChild(fire!)
            spriteOrPlane.addChild(fire2!)
        }
    }
    func replaySceneDidFinish(myScene: ReplayScene, command: String) {
        if (command=="Restart") {
            myScene.view!.removeFromSuperview()
            for idx in 0..<sky.count {
                if idx == skyIndex {
                    sky[idx].numParticlesToEmit = 1  //turn off
                }
            }
            jetIndex += 1
            plane.removeFromParent()
            plane = SKSpriteNode.next(jetIndex)
            myLabel.fontColor = UIColor.random
            myLabel2.fontColor = UIColor.random
            myLabel3.fontColor = UIColor.random
            skyIndex = Int(arc4random() % 3)
            sky[skyIndex].numParticlesToEmit = 0
            sky[skyIndex].position = CGPoint(x: frame.width/2, y: frame.height)
            enemy.position = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
            enemy.physicsBody!.applyImpulse(CGVectorMake(2, 2))
            missile!.hidden = true
            missile!.position = self.plane.position
            isFired = false
            missile2!.hidden = true
            missile2!.position = self.plane.position
            isFired2 = false
            //let missionScore = ((100 * aces) - (lostSprites * 10) - missilesFired - bulletsFired + (missileHits * 5) - (planeDamage * 10))
            aces = 0
            bulletsFired = 0
            lostSprites = 0
            launchedSprites = 0
            missileHits = 0
            missilesFired = 0
            planeDamage = 0
            updateScoreBoard()
            fireButton!.hidden = true
            fireButton2!.hidden = true
            for s in spriteNodes {
                s.removeFromParent()
            }
            addSquadron()
            flyBy()
            setAutoStartTimer()
        } else {
            goToEndgame(myScene, command: command)
        }
    }
    func addSquadron() {
        let planeSavedSpot = CGPoint(x: Int(frame.width*0.5), y: Int(frame.height*Constants.VerticlePosition))
        for _ in 0..<Constants.SquadronSize {
            let sprite = SKSpriteNode.next(jetIndex)
            let scale =  CGFloat.randomInRange(0.12, high: 0.18)
            //print(scale)
            sprite.xScale = scale*scaleFactor
            sprite.yScale = scale
            repeat {  //don't put a sprite on the spot where the plane will animate to
                sprite.position = CGPoint.random(frame)
            } while insertionSpotTaken(sprite.position, reserved: planeSavedSpot)
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
            sprite.zPosition = plane.zPosition - 0.01
            addChild(sprite)
            spriteNodes.append(sprite)
            launchedSprites++
        }
        updateScoreBoard()
    }
    func insertionSpotTaken(test: CGPoint, reserved: CGPoint) -> Bool {
        let airSpace = Int(plane.frame.height/5)
        let dX = (test.x - reserved.x)
        let dY = (test.y - reserved.y)
        if (Int(abs(dX)) < airSpace) && (Int(abs(dY)) < airSpace) {
            return true
        } else {
            return false
        }
    }
    // MARK: - didMoveToView
    override func didMoveToView(view: SKView) {
        /* Setup your REPLAY scene here */
        var replayAdjustment = CGFloat(4)
        if model.hasPrefix("iPad") {
            replayAdjustment = 4  //was 2
        } else {
            replayAdjustment = 6
            scaleFactor = 3.0 / 4.0
        }
        replayView = SKView(frame: CGRect(x: frame.size.width/(replayAdjustment*2), y: frame.size.height/(replayAdjustment*2), width: frame.size.width/replayAdjustment, height: frame.size.height/replayAdjustment))  //replayScene was a let***************
        replayScene = ReplayScene(size: CGSize(width: frame.size.width/replayAdjustment, height: frame.size.height/replayAdjustment))
        replayView!.presentScene(replayScene)
        replayScene!.thisDelegate = self
        
        /* Setup your GAME scene here */
        backgroundColor = UIColor.blackColor()
        //view.ignoresSiblingOrder = true  in GVC
        runAction(SKAction.repeatActionForever(sound0))
        sky = [sky1!, sky2!, sky3!, smoke!, halo!]
        skyIndex = Int(arc4random() % 3)  //3 skys only not smoke or halo
        sky[skyIndex].position = CGPoint(x: frame.width/2, y: frame.height)
        for idx in 0..<sky.count {
            addChild(sky[idx])
            if idx != skyIndex {
                sky[idx].numParticlesToEmit = 1  //turn off
            }
        }
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector.zero
        myLabel.fontColor = UIColor.blueColor()
        myLabel2.fontColor = UIColor.purpleColor()
        myLabel3.fontColor = UIColor.purpleColor()
        myLabel.text = "Guided Missile"
        myLabel.fontSize = 30
        myLabel.position = CGPoint(x: (CGRectGetMidX(frame) + (Constants.Top * 3)), y: (CGRectGetMaxY(frame) - Constants.Top))
        addChild(myLabel)
        myLabel2.position = CGPoint.addPoint(myLabel.position, right: CGPoint(x: 0, y: -Constants.Top))
        myLabel2.fontSize = 30
        addChild(myLabel2)
        myLabel3.position = CGPoint.addPoint(myLabel2.position, right: CGPoint(x: 0, y: -Constants.Top))
        myLabel3.fontSize = 30
        addChild(myLabel3)
        physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)  //wall
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
        enemy.physicsBody!.applyImpulse(CGVector(dx: 2, dy: 2))
        enemy.physicsBody!.categoryBitMask = enemyCategory
        enemy.physicsBody!.collisionBitMask = spriteCategory
        enemy.physicsBody!.contactTestBitMask = spriteCategory
        addSquadron()
        fireText.text = "Fire"
        fireText.fontSize = 20
        fireButton = SKShapeNode(circleOfRadius: fireText.frame.width)
        fireButton!.fillColor = SKColor.redColor()
        fireButton!.yScale = 1.0 / scaleFactor
        fireButton!.name = "fireButton"
        fireButton!.hidden = true
        fireButton!.addChild(fireText)
        addChild(fireButton!)
        fireText2.text = "Fire"
        fireText2.fontSize = 20
        fireButton2 = SKShapeNode(circleOfRadius: fireText2.frame.width)
        fireButton2!.fillColor = SKColor.blueColor()
        fireButton2!.yScale = 1.0 / scaleFactor
        fireButton2!.name = "fireButton2"
        fireButton2!.hidden = true
        fireButton2!.addChild(fireText2)
        addChild(fireButton2!)
        flyBy()
        loadCannon()
//        missile.text = "."
//        missile.fontSize = 60
        missile!.hidden = true
        missile2!.hidden = true
        addChild(missile!)
        addChild(missile2!)
        setAutoStartTimer()
    }
    // MARK: - autoStartTimer
    private func setAutoStartTimer() {
        autoStartTimer =  NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: "fireAutoStart:", userInfo: nil, repeats: true)
    }
    //When the timer fires – and the missle velocity is 0 in dx or dy push it:
    func fireAutoStart(timer: NSTimer) {
        if enemy.physicsBody?.velocity.dx == 0 || enemy.physicsBody?.velocity.dy == 0 {
            enemy.physicsBody!.applyImpulse(CGVector(dx: 2, dy: 2))
        }
    }
    func resetFireButtons() {
        let offset = plane.frame.width
        fireButton!.position = CGPoint(x: plane.position.x + offset , y: plane.position.y+15)  //put it off the right wing edge
        fireButton2!.position = CGPoint(x: plane.position.x - offset, y: plane.position.y+15)  //put it off the left wing edge
    }
    func resetPlane() {
        fireButton!.hidden = false
        fireButton2!.hidden = false
        plane.xScale = Constants.Scale * scaleFactor
        plane.yScale = Constants.Scale
        plane.position = CGPoint(x: frame.size.width/2, y: frame.size.height*Constants.VerticlePosition)
        resetFireButtons()
    }
    // MARK: - touchesMoved
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {  //drag the plane
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
        case Enemy  = 0b0001
        case Plane  = 0b0010
        case Sprite = 0b0100
        case Shell  = 0b1000
    }
    // MARK: - Testing & Tracking PhysicsCategories
    //I like to use a two-tiered approach to contact handlers. First, I check for the kind of collision — is it a wall/enemy collision or a wall/sprite collision or a sprite/enemy collision? Then, if necessary I check to see which body in the collision is which. This doesn't cost much in terms of computation, and it makes it very clear at every point in my code what's going on.
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
            //print("plane + enemy")
            if contact.bodyA.categoryBitMask == PhysicsCategory.Plane.rawValue {
                handleCollision(contact.bodyA.node as! SKSpriteNode,
                    enemy: contact.bodyB.node as! SKLabelNode)
            } else {
                handleCollision(contact.bodyB.node as! SKSpriteNode,
                    enemy: contact.bodyA.node as! SKLabelNode)
            }
        case PhysicsCategory.Enemy.rawValue | PhysicsCategory.Shell.rawValue:
            //print("shell + enemy")
            if contact.bodyB.categoryBitMask == PhysicsCategory.Shell.rawValue {
                handleCollision(contact.bodyA.node as! SKLabelNode,
                    laser: contact.bodyB.node as! SKSpriteNode)
            } else {
                handleCollision(contact.bodyB.node as! SKLabelNode,
                    laser: contact.bodyA.node as! SKSpriteNode)
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
            updateScoreBoard()
        }
        let fire = SKEmitterNode(fileNamed: "Fire")
        sprite.addChild(fire!)
        smoke!.position = sprite.position
        smoke!.numParticlesToEmit = 0  //turn smoke on
        smokeIndex = spriteNodes.indexOf(sprite)!
        sprite.runAction(SKAction.colorizeWithColor(UIColor.random, colorBlendFactor: 1.0, duration: 3))
        if lostSprites % 2 == 0 {
            destroySprite(sprite, crashSound: sound4)
        } else {
            destroySprite(sprite, crashSound: sound3)
        }
    }
    func destroySprite(sprite: SKSpriteNode, crashSound: SKAction) {
        sprite.runAction(crashSound, completion: { [weak self] (success) -> Void in
            sprite.runAction(SKAction.fadeAlphaTo(0, duration: 5))
            let delay = Double(5) * Double(NSEC_PER_SEC)
            let totalTime = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), Int64(delay))
            dispatch_after(totalTime, dispatch_get_main_queue()) { [weak self] (success) -> Void in
                self!.smoke!.numParticlesToEmit = 1  //turn smoke off
                self!.smokeIndex = nil
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
    func handleCollision(enemy: SKLabelNode, laser: SKSpriteNode) {
        halo!.position = enemy.position
        halo!.numParticlesToEmit = 0  //turn on
        aces++      //you defeated the enemy!
        enemy.hidden = true
        updateScoreBoard()  //this checks for enemy.hidden
        enemy.physicsBody!.velocity = CGVectorMake(-1*enemy.physicsBody!.velocity.dx, -1*enemy.physicsBody!.velocity.dy)
        enemy.physicsBody!.dynamic = false
        smoke!.position = enemy.position
        smoke!.numParticlesToEmit = 0  //turn smoke on
        captureBogey(1)  //max score per flight = 100 since 100ace-1shot+1bogey
        replay()
    }
    func goToEndgame(myScene: ReplayScene, command: String) {
        if command == "GameCenter" {
            laser.runAction(sound7)
            gameCenter(UIButton())
            let qualityOfServiceClass = QOS_CLASS_USER_INITIATED
            let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
            dispatch_async(backgroundQueue, { [weak self] in
                print("This is run on the background queue")
                while !self!.gameCenterDone {
                    sleep(1)
                }
                dispatch_async(dispatch_get_main_queue(), { [weak self] in
                    print("This is run on the main queue, after backgroundQueue code in outer closure")
                    if self!.gameCenterDone {
                        self!.replaySceneDidFinish(myScene, command: "Restart")
                        self!.gameCenterDone = false
                    }
                    })
                })
        } else {
            exit(0)
        }
    }
    func planeDidCollideWithEnemy(plane: SKSpriteNode, enemy: SKLabelNode) {
        planeDamage++
        updateScoreBoard()
        let action = SKAction.rotateByAngle(CGFloat(2*M_PI), duration: 2)
        plane.runAction(action)
        captureBogey(0)
        if planeDamage == 3 {  //end of level
            replay()
        }
    }
    func replay() {
        let action = SKAction.moveToY(Constants.Top, duration: 2)
        enemy.runAction(action, completion: { [weak self] (success) -> Void in
            let test = self!.jetIndex + 1
            if test % 3 == 0 {  //only pop question/gameCenter button every third flight
                self!.view!.addSubview(self!.replayView!)
            } else {
                self!.replaySceneDidFinish(self!.replayScene!, command: "Restart")   //replayScene was a let***************
            }
            self!.isFired = false
            self!.isFired2 = false
            self!.enemy.hidden = false
            self!.enemy.physicsBody!.dynamic = true
            self!.halo!.numParticlesToEmit = 1  //turn off
            self!.smoke!.numParticlesToEmit = 1  //turn smoke off
            self!.smokeIndex = nil
            self!.autoStartTimer?.invalidate()
            self!.autoStartTimer = nil
            })
    }
    // MARK: - touchesBegan
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       /* Called when a touch begins */
        for touch in touches {
            if touch.tapCount == 1 {
                let location = touch.locationInNode(self)
                let thisNode = nodeAtPoint(location)
                if (thisNode.name != nil) {
                    if (thisNode.name == fireButton?.name) {
                        fireCannon()
                    } else if (thisNode.name == fireButton2?.name) {
                        fireMissle()
                    }
                }
            } else if touch.tapCount == 2 {
                enemy.physicsBody!.applyImpulse(CGVector(dx: 2, dy: 2))
            }
        }
    }
    var first = true
    func fireMissle() {
        if first {
            first = false
            isFired = true
            soundOn = true
            runAction(sound5)
            missile!.position = plane.position
            missile!.hidden = false
        } else {
            first = true
            isFired2 = true
            soundOn = true
            runAction(sound5)
            missile2!.position = plane.position
            missile2!.hidden = false
        }
        missilesFired++
        updateScoreBoard()
        if missilesFired == 16 {  //end of level
            replay()
        }
    }
    func resetMissiles() {
        let delay = Double(1) * Double(NSEC_PER_SEC)
        let totalTime = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), Int64(delay))
        dispatch_after(totalTime, dispatch_get_main_queue()) { [weak self] (success) -> Void in
            self!.missile!.hidden = true
            self!.missile2!.hidden = true
            self!.isFired = false
            self!.isFired2 = false
            self!.missile!.position = self!.plane.position
            self!.missile2!.position = self!.plane.position
            self!.runAction(self!.sound1)
        }
    }
    func calculateScore() -> Int {
        let score = ((100 * aces) - (lostSprites * 10) - missilesFired - bulletsFired + (missileHits * 5) - (planeDamage * 10))
        return max(0, score)
    }
    func updateScoreBoard() {
        if planeDamage == 3 || missilesFired == 16 || lostSprites == 12 || enemy.hidden {
            if enemy.hidden {
                score = score + calculateScore()
            }
            myLabel.fontColor = UIColor.redColor()
            myLabel.text = "Game Over!   Score: \(score), PD: \(planeDamage)"
            myLabel2.text = "Missiles Fired: \(missilesFired), Bandit Hits: \(missileHits)"
            myLabel3.text = "Lasers Fired: \(bulletsFired), Wingmen Lost: \(lostSprites)"
        } else {
            myLabel.text = "Plane damage: \(planeDamage), Bandit Hits: \(missileHits)"
            myLabel2.text = "Lasers Fired: \(bulletsFired), Wingmen Lost: \(lostSprites)"
            myLabel3.text = ""
        }
    }
    // MARK: - UPDATE()
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        if let idx = smokeIndex {  //reposition smoke on any(optional idx) crashing/burning sprite
            let sprite = spriteNodes[idx]
            smoke?.position = sprite.position
        }
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
        if soundOn {  //needed because update fires too often when capturing enemy
            runAction(sound2)
            missileHits++
            updateScoreBoard()
            resetMissiles()  //hide them after 1 second
        }
        if shot < 2 {
            missile!.position = enemy.position
            let action = SKAction.moveToY(Constants.Top, duration: 0.5)
            enemy.physicsBody!.velocity = CGVector(dx: 0,dy: 0)
            enemy.runAction(action)
            missile!.runAction(action)
            resetSound()
        } else if shot == 2 {
            missile2!.position = enemy.position
            let action = SKAction.moveToY(Constants.Top, duration: 0.5)
            enemy.physicsBody!.velocity = CGVector(dx: 0,dy: 0)
            enemy.runAction(action)
            missile2!.runAction(action)
            resetSound()
        }
    }
    func resetSound() {
        soundOn = false
    }

    func loadCannon() {
        laser.position = CGPoint(x: -10, y: 0)
        laser.hidden = true
        addChild(laser)
        laser.physicsBody = SKPhysicsBody(edgeFromPoint: CGPointZero, toPoint: CGPoint(x: 0, y: laser.frame.size.height))
        laser.physicsBody!.categoryBitMask = shellCategory
        laser.physicsBody!.collisionBitMask = enemyCategory
        laser.physicsBody!.contactTestBitMask = enemyCategory
    }
    func fireCannon() {
        bulletsFired++
        updateScoreBoard()
        laser.hidden = false
        var laserSequence = [SKAction]()
        laser.position = CGPointMake(plane.position.x, plane.position.y + plane.frame.height/2)
        //print(laser.position)
        laserSequence.append(sound6)
        let action = SKAction.moveToY(frame.height, duration: 0.5)
        laserSequence.append(action)
        laserSequence.append(sound7)
        laser.runAction(SKAction.sequence(laserSequence), completion: { [weak self] (success) -> Void in
            self!.laser.hidden = true
            self!.laser.position = CGPoint(x: -10, y: 0)
            })
    }
    // MARK: GameCenter
    var gameCenterAchievements=[String:GKAchievement]() //dictionary...send high score to leaderboard
    // load prev achievement granted to the player
    func gameCenterLoadAchievements(){
        // load all prev. achievements for GameCenter for the user so progress can be added
        GKAchievement.loadAchievementsWithCompletionHandler( { [weak self] (allAchievements, error) -> Void in
            if error != nil {
                print("Game Center: could not load achievements, error: \(error)")
            } else {
                for anAchievement in allAchievements!  {
                    let oneAchievement = anAchievement
                    self!.gameCenterAchievements[oneAchievement.identifier!]=oneAchievement
                }
            }
            })
    }
    // add progress to an achievement
    func gameCenterAddProgressToAnAchievement(progress:Double, achievementID:String) {
        let gvc = view!.window!.rootViewController as! GameViewController
        if gvc.canUseGameCenter == true { // only update progress if user opt-in to use Game Center
            // lookup if prev progress is logged for this achievement = achievement is already known (and loaded) from Game Center for this user
            let lookupAchievement:GKAchievement? = gameCenterAchievements[achievementID]
            if let achievement = lookupAchievement {
                // found the achievement with the given achievementID, check if it already 100% done
                if achievement.percentComplete != 100 {
                    // set new progress
                    achievement.percentComplete = progress
                    if progress == 100.0  { achievement.showsCompletionBanner=true }  // show banner only if achievement is fully granted (progress is 100%)
                    // try to report the progress to the Game Center
                    GKAchievement.reportAchievements([achievement], withCompletionHandler: { (error) -> Void in
                        if error != nil {
                            print("Couldn't save achievement (\(achievementID)) progress to \(progress) %")
                        }
                    })
                }
                else {// achievemnt already granted, nothing to do
                    print("DEBUG: Achievement (\(achievementID)) already granted")
                }
            } else { // never added  progress for this achievement, create achievement now, recall to add progress
                print("No achievement with ID (\(achievementID)) was found, no progress for this one was recoreded yet. Create achievement now.")
                gameCenterAchievements[achievementID] = GKAchievement(identifier: achievementID)
                // recursive recall this func now that the achievement exist
                gameCenterAddProgressToAnAchievement(progress, achievementID: achievementID)
            }
        }
    }
    func saveHighscore(score: Int) {
        let gvc = view!.window!.rootViewController as! GameViewController
        //check if user is signed in
        if gvc.gameCenterPlayer.authenticated {
            let scoreReporter = GKScore(leaderboardIdentifier: "com.garthmackenzie.SortIt.leaderboard") //leaderboard id here
            scoreReporter.value = Int64(score)
            let scoreArray: [GKScore] = [scoreReporter]
            GKScore.reportScores(scoreArray, withCompletionHandler: { [weak self] (error) -> Void in
                if error != nil {
                    print("error posting scoreArray to Game Center")
                } else {
                    self!.showLeader()
                }
            })
        }
    }
    //shows leaderboard screen
    func showLeader() {
        let vc = self.view?.window?.rootViewController
        let gc = GKGameCenterViewController()
        gc.gameCenterDelegate = self
        vc!.presentViewController(gc, animated: true, completion: nil)
    }
    var gameCenterDone = false
    //hides leaderboard screen
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismissViewControllerAnimated(true, completion: { [weak self] (success) -> Void in
            self!.gameCenterDone = true
            })
    }
    @IBAction func gameCenter(sender: UIButton) {
        //0-1 ace, max(16)missilesFired, unlimited bullets, max(12+flyBy)lostSprites, max(3)planeDamage per flight
        if score > 0 {
            saveHighscore(score)  //showLeader()
            let gvc = view!.window!.rootViewController as! GameViewController
            if gvc.canUseGameCenter {
                gameCenterLoadAchievements()
                var percent = (Double(score) / 10.0)
                //print(percent)
                gameCenterAddProgressToAnAchievement(percent, achievementID: "com.garthmackenzie.SortIt.points.1000")
                percent = Double(score) / 20.0
                gameCenterAddProgressToAnAchievement(percent, achievementID: "com.garthmackenzie.SortIt.points.2000")
                percent = Double(score) / 30.0
                gameCenterAddProgressToAnAchievement(percent, achievementID: "com.garthmackenzie.SortIt.points.3000")
                percent = Double(score) / 50.0
                gameCenterAddProgressToAnAchievement(percent, achievementID: "com.garthmackenzie.SortIt.points.5000")
                percent = Double(jetIndex) / 0.25
                gameCenterAddProgressToAnAchievement(percent, achievementID: "com.garthmackenzie.SortIt.level.25")
                percent = Double(jetIndex) / 0.50
                gameCenterAddProgressToAnAchievement(percent, achievementID: "com.garthmackenzie.SortIt.level.50")
                percent = Double(jetIndex) / 0.75
                gameCenterAddProgressToAnAchievement(percent, achievementID: "com.garthmackenzie.SortIt.level.75")
                percent = Double(jetIndex)
                gameCenterAddProgressToAnAchievement(percent, achievementID: "com.garthmackenzie.SortIt.level.100")
            }
        }
    }
}

private extension CGFloat {
    static func randomInRange(low: CGFloat, high: CGFloat) -> CGFloat {   //print(UInt32.max) = 4294967295
        let value = CGFloat(arc4random()) / CGFloat(UInt32.max)
        return value * (high - low) + low
    }
}
private extension CGPoint {
    static func addPoint(left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    static func random(frame: CGRect) -> CGPoint {  //random sprite(center) location within bordered frame
        let border = 40
        let x = Int(frame.maxX) - border*2
        let y = Int(frame.maxY) - border*2
        return CGPoint(x: Int(arc4random() % UInt32(x)) + border, y: Int(arc4random() % UInt32(y)) + border)
    }
}
private extension CGVector {
    static func radiansToVector(radians: Double) -> CGVector {  //low = 200.0 * M_PI / 180.0
        return CGVector(dx: cos(radians), dy: sin(radians))    //high = 340.0 * M_PI / 180.0
    }
}
private extension SKSpriteNode {
    class var random: SKSpriteNode {
        switch arc4random() % 14 {
            case 0: return SKSpriteNode(imageNamed:"F-15Z1")
            case 1: return SKSpriteNode(imageNamed:"MiG-29MZ")
            case 2: return SKSpriteNode(imageNamed:"Su-33")
            case 3: return SKSpriteNode(imageNamed:"F1444842379440")
            case 4: return SKSpriteNode(imageNamed:"F-104 Starfighter")
            case 5: return SKSpriteNode(imageNamed:"F-15")
            case 6: return SKSpriteNode(imageNamed:"F-RussianZ1")
            case 7: return SKSpriteNode(imageNamed:"T-50")
            case 8: return SKSpriteNode(imageNamed:"MiG-29Z")
            case 9: return SKSpriteNode(imageNamed:"F-15Z")
            case 10: return SKSpriteNode(imageNamed:"F-35AZ")
            case 11: return SKSpriteNode(imageNamed:"F-18")
            case 12: return SKSpriteNode(imageNamed:"F-4")
            case 13: return SKSpriteNode(imageNamed:"F-35A")
            default: return SKSpriteNode(imageNamed:"F-35AZ")
        }
    }
    static func next(index: Int) -> SKSpriteNode {
        switch index % 14 {
            case 0: return SKSpriteNode(imageNamed:"F-15Z1")
            case 1: return SKSpriteNode(imageNamed:"MiG-29MZ")
            case 2: return SKSpriteNode(imageNamed:"Su-33")
            case 3: return SKSpriteNode(imageNamed:"F1444842379440")
            case 4: return SKSpriteNode(imageNamed:"F-104 Starfighter")
            case 5: return SKSpriteNode(imageNamed:"F-15")
            case 6: return SKSpriteNode(imageNamed:"F-RussianZ1")
            case 7: return SKSpriteNode(imageNamed:"T-50")
            case 8: return SKSpriteNode(imageNamed:"MiG-29Z")
            case 9: return SKSpriteNode(imageNamed:"F-15Z")
            case 10: return SKSpriteNode(imageNamed:"F-35AZ")
            case 11: return SKSpriteNode(imageNamed:"F-18")
            case 12: return SKSpriteNode(imageNamed:"F-4")
            case 13: return SKSpriteNode(imageNamed:"F-35A")
            default: return SKSpriteNode(imageNamed:"F-35AZ")
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
