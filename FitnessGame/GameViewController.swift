//
//  GameViewController.swift
//
//  Created by Peter Sun on 10/16/2022.
//  Copyright © 2022 Peter Sun. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    var scene : GameScene?
    var isFitnessGoalAchieved = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scene = GameScene(size: view.bounds.size)
        scene?.parentViewController = self
        scene?.isFitnessGoalAchieved = self.isFitnessGoalAchieved
        //setup game scene
        let skView = view as! SKView // the view in storyboard must be an SKView
        skView.showsFPS = true // show some debugging of the FPS
        skView.showsNodeCount = true // show how many active objects are in the scene
        skView.ignoresSiblingOrder = true // don't track who entered scene first
        scene?.scaleMode = .resizeFill
        skView.presentScene(scene)
    }
    
    // don't show the time and status bar at the top
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    public func setBonusCredit(isGoalAchieved : Bool) {
        self.scene?.isFitnessGoalAchieved = isGoalAchieved
    }
    
    
    
}
