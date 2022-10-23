//
//  GameScene.swift
//
//  Created by Peter Sun on 10/16/2022.
//  Copyright © 2022 Peter Sun. All rights reserved.
//

import UIKit
import SpriteKit
import CoreMotion

enum GAMESTATE {
    case starting; case started; case playing; case ended
}

class GameScene: SKScene, SKPhysicsContactDelegate {

    var isFitnessGoalAchieved = true
    
    // if isFitnessGoalAchieved, use bonus credit
    let DEFAULT_CREDIT = 3
    let BONUS_CREDIT = 10
    let WINNING_SCORE = 20
    
    // MARK: background image variables
    var introBackground = SKSpriteNode(imageNamed: "intro")
    var playingBackground = SKSpriteNode(imageNamed: "room1")
    var winningBackground = SKSpriteNode(imageNamed: "toon")
    var losingBackground = SKSpriteNode(imageNamed: "Bossbotthebigcheese")
    var bonus = SKSpriteNode(imageNamed: "bonus")
    
    // MARK: sound variables
    var hurt = SKAction.playSoundFileNamed("hurt.wav", waitForCompletion: false)
    var hit = SKAction.playSoundFileNamed("stump.wav", waitForCompletion: false)
    var won = SKAction.playSoundFileNamed("won.wav", waitForCompletion: false)
    var dead = SKAction.playSoundFileNamed("dead.wav", waitForCompletion: false)
    var recharge = SKAction.playSoundFileNamed("recharge.wav", waitForCompletion: false)
    var overture = SKAction.playSoundFileNamed("overture.wav", waitForCompletion: false)
    
    // MARK: Raw Motion Functions
    let motion = CMMotionManager()
    var isPlay = false
    
    
    func startMotionUpdates(){
        // if motion is available, start updating the device motion
        if self.motion.isDeviceMotionAvailable{
            self.motion.deviceMotionUpdateInterval = 0.2
            self.motion.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: self.handleMotion )
        }
    }
    
    func handleMotion(_ motionData:CMDeviceMotion?, error:Error?){
        // make gravity in the game als the simulator gravity
        if let gravity = motionData?.gravity {
            self.physicsWorld.gravity = CGVector(dx: CGFloat(9.8*gravity.x), dy: CGFloat(9.8*gravity.y))
        }
        
        if let userAccel = motionData?.userAcceleration{
            // cannot move a pinned block?
            
            if (spinBlock.position.x < 0 && userAccel.x < 0) || (spinBlock.position.x > self.size.width && userAccel.x > 0)
            {
                // do not update the position
                return
            }
            let action = SKAction.moveBy(x: userAccel.x*100, y: 0, duration: 0.1)
            self.spinBlock.run(action, withKey: "temp")
            
        }
    }
    
    var gameState: GAMESTATE = .starting {
        didSet {
            // 1. if game state is in starting, show game description
            // 2. if game state is in playing, start game
            // 3. if game state is ended, show end label
            switch gameState {
            case .starting: break
            case .started:
                // 1. display game intro
                run(overture)
                introBackground.zPosition = 1
                introBackground.position = CGPoint(x: frame.size.width/2, y: frame.size.height/2 )
                addChild(introBackground)
            case .playing:
                removeChildren(in: [introBackground])

                // 1. set background for playing
                playingBackground.zPosition = -15
                playingBackground.position = CGPoint(x: frame.size.width/2, y: frame.size.height/4 )
                addChild(playingBackground)
                
                //backgroundColor = SKColor.black
                // start motion for gravity
                self.startMotionUpdates()
                // make sides to the screen
                self.addRoom()
                // add in the interaction sprite
                self.addCog()
                self.addToon()
                
                // add a scorer
                self.addScore()
                
            case .ended:
                // set end label
                break
            }
        }
    }
    
    // MARK: =====Delegate Functions=====
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //self.addCog()
        if gameState == .started {
            if isFitnessGoalAchieved {
                self.score = BONUS_CREDIT
                // if goal achieved, give 10 points and play sound, wait 1 second before playing
                bonus.zPosition = 2
                bonus.position = CGPoint(x: frame.size.width/2, y: frame.size.height/2 )
                addChild(bonus)
                run(recharge)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.removeChildren(in: [self.bonus])
                    self.gameState = .playing
                }
            } else {
                self.score = DEFAULT_CREDIT
                gameState = .playing
            }
            
        }
    }
    
    // MARK: View Hierarchy Functions
    // this is like out "View Did Load" function
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        
        // start the game
        self.gameState = .started
        
        // update a special watched property for score
        self.isPlay = true
    }
    
    // MARK: Create Sprites Functions
    let spinBlock = SKSpriteNode()
    let scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
    
    var score:Int = 10 {
        willSet(newValue){
            DispatchQueue.main.async{
                self.scoreLabel.text = "Score: \(newValue)"
            }
        }
    }
    
    func addScore(){
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = SKColor.white
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 60)
        addChild(scoreLabel)
    }
    
    let toon = SKSpriteNode(imageNamed: "toon")
    func addToon(){
        
        toon.size = CGSize(width:size.width*0.15,height:size.height * 0.15)
        
        toon.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        
        toon.physicsBody = SKPhysicsBody(rectangleOf:toon.size)
        toon.physicsBody?.restitution = random(min: CGFloat(1.1), max: CGFloat(1.6))
        toon.physicsBody?.isDynamic = true
        // for collision detection we need to setup these masks
        toon.physicsBody?.contactTestBitMask = 0x00000001
        toon.physicsBody?.collisionBitMask = 0x00000001
        toon.physicsBody?.categoryBitMask = 0x00000001
        
        self.addChild(toon)
    }
    
    let cog = SKSpriteNode(imageNamed: "Bossbotthebigcheese")
    func addCog(){
        cog.size = CGSize(width:size.width*0.2,height:size.height * 0.2)
        
        let randNumber = random(min: CGFloat(0.1), max: CGFloat(0.9))
        cog.position = CGPoint(x: size.width * randNumber, y: size.height * 0.75)
        
        cog.physicsBody = SKPhysicsBody(rectangleOf:cog.size)
        cog.physicsBody?.restitution = random(min: CGFloat(1.0), max: CGFloat(1.5))
        cog.physicsBody?.isDynamic = true
        // for collision detection we need to setup these masks
        cog.physicsBody?.contactTestBitMask = 0x00000001
        cog.physicsBody?.collisionBitMask = 0x00000001
        cog.physicsBody?.categoryBitMask = 0x00000001
        
        self.addChild(cog)
    }
    
    let poisonBottom = SKSpriteNode()
    let poisonRight = SKSpriteNode()
    func addRoom(){
        let left = SKSpriteNode()
        let top = SKSpriteNode()
        
        left.size = CGSize(width:size.width*0.1,height:size.height)
        left.position = CGPoint(x:0, y:size.height*0.5)
        
        poisonRight.size = CGSize(width:size.width*0.1,height:size.height)
        poisonRight.position = CGPoint(x:size.width, y:size.height*0.5)
        
        top.size = CGSize(width:size.width,height:size.height*0.1)
        top.position = CGPoint(x:size.width*0.5, y:size.height)
        
        poisonBottom.size = CGSize(width:size.width,height:size.height*0.1)
        poisonBottom.position = CGPoint(x:size.width*0.5, y:0)
        
        for obj in [left,top]{
            obj.color = UIColor.blue
            obj.physicsBody = SKPhysicsBody(rectangleOf:obj.size)
            obj.physicsBody?.isDynamic = true
            obj.physicsBody?.pinned = true
            obj.physicsBody?.allowsRotation = false
            self.addChild(obj)
        }
        
        for obj in [poisonRight,poisonBottom]{
            obj.color = UIColor.red
            obj.physicsBody = SKPhysicsBody(rectangleOf:obj.size)
            obj.physicsBody?.isDynamic = true
            obj.physicsBody?.pinned = true
            obj.physicsBody?.allowsRotation = false
            obj.physicsBody?.contactTestBitMask = 0x00000001
            obj.physicsBody?.collisionBitMask = 0x00000001
            obj.physicsBody?.categoryBitMask = 0x00000001
            self.addChild(obj)
        }
    }
    

    
    let endLabel = SKLabelNode(fontNamed: "Chalkduster")
    // here is our collision function
    func didBegin(_ contact: SKPhysicsContact) {
        guard self.isPlay else { return }
        
        /**function to display end label*/
        func displayEndLabel(text: String, color: SKColor) {
            self.removeChildren(in: [playingBackground])
            self.endLabel.fontSize = 40
            self.endLabel.fontColor = color
            self.endLabel.position = CGPoint(x: (self.frame.midX), y: (self.frame.midY + 40))
            self.endLabel.text = text
            self.toon.physicsBody?.restitution = 2.0
            self.addChild(self.endLabel)
        }
        
        let toonHitCog = (contact.bodyA.node == toon && contact.bodyB.node == cog) ||
        (contact.bodyB.node == toon && contact.bodyA.node == cog)
        
        let toonHitPoisonWalls = (contact.bodyA.node == toon && (contact.bodyB.node == poisonBottom || contact.bodyB.node == poisonRight)) || ((contact.bodyA.node == poisonBottom || contact.bodyA.node == poisonRight) && contact.bodyB.node == toon)
        
        // if anything interacts with the spin Block, then we should update the score
        if toonHitCog
        {
            self.run(hit)
            self.score += 1
        } else if  toonHitPoisonWalls {
            self.run(hurt)
            self.score -= 1
        }
        
        if self.score >= WINNING_SCORE {
            self.removeChildren(in: [self.scoreLabel])
            
            self.isPlay = false
            self.gameState = .ended
            
            let explodeEmmiter = SKEmitterNode(fileNamed: "explode")
            explodeEmmiter!.position = self.cog.position
            addChild(explodeEmmiter!)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){ // wait 1 second so we can remove explosion
                self.removeChildren(in: [self.cog, explodeEmmiter!])
                self.backgroundColor = .cyan
                self.winningBackground.zPosition = -15
                self.winningBackground.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2 )
                
                self.addChild(self.winningBackground)
                let winEmmiter = SKEmitterNode(fileNamed: "bokeh")
                winEmmiter!.position = self.winningBackground.position
                self.addChild(winEmmiter!)
                displayEndLabel(text: "You win!", color: SKColor.orange)
                self.poisonRight.color = .blue
                self.poisonBottom.color = .blue
                
                self.run(self.won)
            }
            
        } else if self.score <= 0 {
            self.isPlay = false
            self.gameState = .ended
            self.removeChildren(in: [toon])
            
            self.backgroundColor = .black
            self.losingBackground.zPosition = -15
            self.losingBackground.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2 )
            self.addChild(self.losingBackground)
            
            run(dead)
            displayEndLabel(text: "Cog win!", color: SKColor.red)
        }
    }
    
    // MARK: Utility Functions (thanks ray wenderlich!)
    // generate some random numbers for cor graphics floats
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(Int.max))
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    var animationTimer: Timer?
    func resetAndPlayDemoAnimation() {
        
    }
}
