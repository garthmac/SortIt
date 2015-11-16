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
        let leftMargin = view.bounds.width/4
        let topMargin = view.bounds.height/4
        
        let question = SKLabelNode(fontNamed:"Arial")
        question.text = "Play Again?"
        question.fontSize = 30
        question.position = CGPoint(x: leftMargin + 50, y: view.bounds.height - topMargin)
        self.addChild(question)
        
        let playAgainButton =
        UIButton(frame: CGRect(origin: CGPoint(x: leftMargin, y: topMargin + 30), size: CGSize(width: 100, height: 50)))
        playAgainButton.backgroundColor = UIColor.clearColor()
        playAgainButton.setTitle("Yes", forState: UIControlState.Normal)
        playAgainButton.setTitleColor(UIColor.greenColor(), forState: UIControlState.Normal)
        playAgainButton.addTarget(self, action: "buttonAction:", forControlEvents: UIControlEvents.TouchDown)
        self.view!.addSubview(playAgainButton)
        
        let quitButton =
        UIButton(frame: CGRect(origin: CGPoint(x: leftMargin, y: topMargin + 80), size: CGSize(width: 100, height: 50)))
        quitButton.backgroundColor = UIColor.clearColor()
        quitButton.setTitle("No", forState: UIControlState.Normal)
        quitButton.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
        quitButton.addTarget(self, action: "buttonAction:", forControlEvents: UIControlEvents.TouchDown)
        self.view!.addSubview(quitButton)
    }
    func buttonAction(sender:UIButton!) {
        if sender!.currentTitle=="Yes" {
            // close ReplayScene and start the game again
            thisDelegate!.replaySceneDidFinish(self, command: "Restart")
        } else {
            thisDelegate!.replaySceneDidFinish(self, command: "Quit")
        }
    }
    
    
}
