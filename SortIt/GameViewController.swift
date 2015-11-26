
//
//  GameViewController.swift
//  SortIt
//
//  Created by iMac 27 on 2015-11-13.
//  Copyright (c) 2015 iMac 27. All rights reserved.
//

import UIKit
import SpriteKit
import GameKit

class GameViewController: UIViewController {
    // Game Center
    let gameCenterPlayer=GKLocalPlayer.localPlayer()
    var canUseGameCenter:Bool = false {
        didSet {
            if canUseGameCenter == true {// load prev. achievments form Game Center
                gameScene!.gameCenterLoadAchievements()
            }
        }
    }
//    var lastBounds = CGRectZero
    var gameScene: GameScene? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        gameCenterPlayer.authenticateHandler = { (gameCenterVC:UIViewController?, gameCenterError) -> Void in
            if gameCenterVC != nil {
                self.presentViewController(gameCenterVC!, animated: true, completion: { () -> Void in
                })
            }
            else if self.gameCenterPlayer.authenticated == true {
                self.canUseGameCenter = true
            } else  {
                self.canUseGameCenter = false
            }
            if gameCenterError != nil {
                print("Game Center error: \(gameCenterError)")
            }
        }
        if let scene = GameScene(fileNamed:"GameScene") {
            gameScene = scene
//            lastBounds = gameScene!.frame
            // Configure the view.
            let skView = self.view as! SKView
            skView.showsFPS = false
            skView.showsNodeCount = false
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .Fill
            
            skView.presentScene(scene)
        }
    }
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        if !CGRectEqualToRect(view.bounds, lastBounds) {
//            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {  //phone is landscape only
//                boundsChanged()
//                lastBounds = view.bounds
//            }
//        }
//    }
//    func boundsChanged() {
//        if lastBounds.width < gameScene!.frame.width {
//            for s in gameScene!.spriteNodes {
//                s.yScale = s.yScale / 0.67
//            }
//            gameScene!.fireButton!.yScale = gameScene!.fireButton!.yScale / 0.67
//            gameScene!.fireButton2!.yScale = gameScene!.fireButton2!.yScale / 0.67
//            print(gameScene!.plane.yScale)  //0.1675  wider screen
//            gameScene!.plane.yScale = gameScene!.plane.yScale / 0.67  //=0.25
//        } else {
//            for s in gameScene!.spriteNodes {
//                s.yScale = s.yScale * 0.67
//            }
//            gameScene!.fireButton!.yScale = 0.67
//            gameScene!.fireButton2!.yScale = 0.67
//            print(gameScene!.plane.yScale)  //0.25  taller screen
//            gameScene!.plane.yScale = gameScene!.plane.yScale * 0.67  //=0.1675
//        }
//    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .Landscape
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
