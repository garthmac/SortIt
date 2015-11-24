//
//  ReplayScene.swift
//  SortIt
//
//  Created by iMac 27 on 2015-11-15.
//  Copyright © 2015 iMac 27. All rights reserved.
//

import SpriteKit

protocol ReplaySceneDelegate {
    func replaySceneDidFinish(myScene:ReplayScene, command:String)
}

class ReplayScene: SKScene {
    var thisDelegate: ReplaySceneDelegate?
    
    override func didMoveToView(view: SKView) {
        let leftMargin = view.bounds.width/3
        let topMargin = view.bounds.height/3
        
        let question = SKLabelNode(fontNamed:"Arial")
        question.text = "Next Mission?"
        question.fontSize = 20
        question.position = CGPoint(x: leftMargin + 30, y: view.bounds.height - topMargin)
        self.addChild(question)
        
        let playAgainButton = UIButton(frame: CGRect(origin: CGPoint(x: leftMargin - 40, y: topMargin + 40), size: CGSize(width: 80, height: 20)))
        playAgainButton.backgroundColor = UIColor.clearColor()
        playAgainButton.setTitle("Yes Sir!", forState: UIControlState.Normal)
        playAgainButton.setTitleColor(UIColor.greenColor(), forState: UIControlState.Normal)
        playAgainButton.addTarget(self, action: "buttonAction:", forControlEvents: UIControlEvents.TouchDown)
        self.view!.addSubview(playAgainButton)
        
        let gameCenterButton = UIButton(frame: CGRect(origin: CGPoint(x: leftMargin + 60, y: topMargin + 30), size: CGSize(width: 50, height: 50)))
        if let image = UIImage(named: "gameCenter.png") {
            gameCenterButton.setImage(image, forState: .Normal)
        }
        gameCenterButton.addTarget(self, action: "buttonAction:", forControlEvents: UIControlEvents.TouchDown)
        self.view!.addSubview(gameCenterButton)
    }
    func buttonAction(sender:UIButton!) {
        if sender!.currentTitle=="Yes Sir!" {
            // close ReplayScene and start the game again
            thisDelegate!.replaySceneDidFinish(self, command: "Restart")
        } else {
            thisDelegate!.replaySceneDidFinish(self, command: "GameCenter")
        }
    }
    
    
}
