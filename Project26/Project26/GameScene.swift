//
//  GameScene.swift
//  Project26
//
//  Created by Brandon Johns on 5/25/23.
//

import SpriteKit
import GameplayKit
import CoreMotion

enum CollisionTypes: UInt32
{
    case player = 1
    case wall = 2
    case star = 4
    case vortex = 8
    case finish = 16
    
}//CollisionTypes



class GameScene: SKScene, SKPhysicsContactDelegate
{
    var level = 1
    var player: SKSpriteNode!
    var lastTouchPosition: CGPoint?
    
    var motionManger: CMMotionManager?                                                      // acceration
    
    var scoreLabel: SKLabelNode!
    
    var isGameOver = false
    
    var score = 0
    {
        didSet
        {
            scoreLabel.text = "Score: \(score)"
        }
    }
    override func didMove(to view: SKView)
    {
        background()
        loadLevel()
        createPlayer()
        scoreLabel_Label()
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self                                             //tell us when a collision happens
        
        motionManger = CMMotionManager()
        motionManger?.startAccelerometerUpdates()
        
    }//didMove
    
    func loadLevel()
    {
        guard let levelURL = Bundle.main.url(forResource: "level\(level)", withExtension: "txt") else
        { fatalError("Cannot find level\(level) in the app bundle")
            
        }                                                                                                       //load level if not exit
        
        guard let levelString = try? String(contentsOf: levelURL) else
        {
            fatalError("could not load level1 from the app bundle")
        }                                                                                                       //load the level into a string if not exit

        let lines = levelString.components(separatedBy: "\n")                                                   // sperate contents by a new line
        
        for (row, line) in lines.reversed().enumerated()                                                        //spriteKit reads y on the bottom left corner
        {
            for (column, letter) in line.enumerated()
            {
                let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32 )
                
                if letter == "x"
                {
                    wall(position: position)
                    
                }//wall
                
                else if letter == "v"
                {
                    vortex(position: position)
                }//vortex
                
                else if letter == "s"
                {
                    star(position: position)
                }//star
                else if letter == "f"
                {
                    finish(position: position)
                }//finish
                else if letter == " "
                {
                    //empty space do nothing
                }//empty space
                else
                {
                    fatalError("unknown level letter: \(letter)")
                }
                
            }//for column
            
        }// for row
        
    }//loadLevel
    
   func createPlayer()
    {
        player = SKSpriteNode(imageNamed: "player")
        player.position = CGPoint(x: 96, y: 672)
        player.zPosition = 1
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.5
        
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = CollisionTypes.star.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.finish.rawValue // player hits this
                                                                                                                                                // combine the collision
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        
        addChild(player)
    }//player
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let touch = touches.first else {return}
        let location = touch.location(in: self)
        lastTouchPosition = location
    }//touchesBegan
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let touch = touches.first else {return}
        let location = touch.location(in: self)
        lastTouchPosition = location
    }//touchesMoved
    
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }//touchesEnded
    
    override func update(_ currentTime: TimeInterval)
    {
        
        guard isGameOver == false else {return}                                              //game over no control over game
        #if targetEnvironment(simulator)                                                    //only runs in the simulator
        if let lastTouchPosition = lastTouchPosition
        {
            let difference = CGPoint(x: lastTouchPosition.x - player.position.x, y: lastTouchPosition.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: difference.x / 100 , dy: difference.y / 100)
        }
        
        #else                                                                               //starts real device
        if let accelerometerData = motionManger?.accelerometerData
        {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50, dy: accelerometerData.acceleration.x * 50) // x and y switched because its in landscape mode
        }
        
        #endif
        
    }//update
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else {return}
        
        guard let nodeB = contact.bodyB.node else {return}
        
        if nodeA == player
        {
            playerCollided(with: nodeB)
        }// nodeA
        
        else if nodeB == player
        {
            playerCollided(with: nodeA)
        }
        
        
    }//didBegin
    
    func playerCollided(with node: SKNode)
    {
        if node.name == "vortex"
        {
            player.physicsBody?.isDynamic = false                                               // stop the ball from rolling so it can be sucked into vortex
            isGameOver = true
            score -= 1
            
            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(to: 0.0001, duration: 0.25)
            
            let remove = SKAction.removeFromParent()
            
            let sequence = SKAction.sequence([move, scale, remove])
            
            player.run(sequence){ [weak self ] in
                self?.createPlayer()
                self?.isGameOver = false
            }
            
        }//vortex node
        
        else if node.name == "star"
        {
            node.removeFromParent()
            score += 1
        }//star
        
        else if node.name == "finish"
        {
            removeAllChildren()
            level += 1
            lastTouchPosition = nil
            
            loadLevel()
            didMove(to: self.view!)
        }//finish
        
    }//playerCollided
    
    
    
    
    
    
    
    
    
    
    
    
    func scoreLabel_Label()
    {
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.zPosition = 2
        
        addChild(scoreLabel)
    }
    
    
    func wall(position: CGPoint)
    {
        let node_wall = SKSpriteNode(imageNamed: "block")
        node_wall.position = position
        
        node_wall.physicsBody = SKPhysicsBody(rectangleOf: node_wall.size)
        node_wall.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue                         //rawValue is required to extract the value
        node_wall.physicsBody?.isDynamic = false                                                     //turns off physics
        addChild(node_wall)
    }//wall
    
    func vortex(position: CGPoint)
    {
        let node_vortex = SKSpriteNode(imageNamed: "vortex")
        node_vortex.name = "vortex"
        node_vortex.position = position
        
        node_vortex.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi , duration: 1)))           // rotates by 180 degrees everyone 1 second
        node_vortex.physicsBody = SKPhysicsBody(circleOfRadius: node_vortex.size.width / 2)
        
        node_vortex.physicsBody?.isDynamic = false                                                     //turns off physics
        node_vortex.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue                         //rawValue is required to extract the value
        node_vortex.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue                    //want to know when contact with player
        node_vortex.physicsBody?.collisionBitMask = 0                                                  //nothing bounces off it
        addChild(node_vortex)
    }
    func star(position: CGPoint)
    {
        //load star
        let node_star = SKSpriteNode(imageNamed: "star")
        node_star.name = "star"
        node_star.position = position
        
        node_star.physicsBody = SKPhysicsBody(circleOfRadius: node_star.size.width / 2)
        
        node_star.physicsBody?.isDynamic = false
        node_star.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
        node_star.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue                    //want to know when contact with player
        node_star.physicsBody?.collisionBitMask = 0                                                  //nothing bounces off it
        addChild(node_star)
        
    }//star
    
    func finish(position: CGPoint)
    {
        //load finish
        let node_finish = SKSpriteNode(imageNamed: "finish")
        node_finish.name = "finish"
        node_finish.position = position
        
        node_finish.physicsBody = SKPhysicsBody(circleOfRadius: node_finish.size.width / 2)
        
        node_finish.physicsBody?.isDynamic = false
        node_finish.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
        node_finish.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue                    //want to know when contact with player
        node_finish.physicsBody?.collisionBitMask = 0                                                  //nothing bounces off it
        addChild(node_finish)
    }//finish
    
    func background()
    {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x:512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
    }//background
    
}//GameScene
