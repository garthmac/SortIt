
//
//  GameViewController.swift
//  SortIt
//
//  Created by iMac 27 on 2015-11-13.
//  Copyright (c) 2015 iMac 27. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    var lastBounds = CGRectZero
    var gameScene: GameScene? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        if let scene = GameScene(fileNamed:"GameScene") {
            gameScene = scene
            lastBounds = gameScene!.frame
            // Configure the view.
            let skView = self.view as! SKView
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .Fill
            
            skView.presentScene(scene)
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !CGRectEqualToRect(view.bounds, lastBounds) {
            boundsChanged()
            lastBounds = view.bounds
        }
    }
    func boundsChanged() {
        if lastBounds.width == gameScene!.frame.width {
//            for s in gameScene!.spriteNodes {
//                s.yScale = s.yScale * 0.67
//            }
            gameScene!.fireButton!.yScale = 0.67
            gameScene!.fireButton2!.yScale = 0.67
//            gameScene!.plane.yScale = gameScene!.plane.yScale * 0.67
        } else {
//            for s in gameScene!.spriteNodes {
//                s.yScale = s.yScale / 0.67
//            }
            gameScene!.fireButton!.yScale = gameScene!.fireButton!.yScale / 0.67
            gameScene!.fireButton2!.yScale = gameScene!.fireButton2!.yScale / 0.67
//            gameScene!.plane.yScale = gameScene!.plane.yScale / 0.67
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
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
