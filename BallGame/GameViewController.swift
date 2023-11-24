//
//  GameViewController.swift
//  BallGame
//
//  Created by Mauro Arantes on 24/11/2023.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {
    
    let categoryTree = 2
    
    var sceneView: SCNView!
    var scene: SCNScene!
    
    var ballNode: SCNNode!
    var selfieStickNode: SCNNode!
    
    var motion = MotionHelper()
    var motionForce = SCNVector3(0, 0, 0)
    
    var sounds: [String: SCNAudioSource] = [:]

    override func viewDidLoad() {
        setupScene()
        setupNodes()
        setupSounds()
    }
    
    func setupScene() {
        sceneView = self.view as? SCNView
        
        sceneView.delegate = self
        
//        sceneView.allowsCameraControl = true
        scene = SCNScene(named: "art.scnassets/MainScene.scn")
        
        scene.physicsWorld.contactDelegate = self
        
        sceneView.scene = scene
        
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        
        tapRecognizer.addTarget(self, action: #selector(GameViewController.sceneViewTapped(recognizer:)))
        sceneView.addGestureRecognizer(tapRecognizer)
    }
    
    func setupNodes() {
        ballNode = scene.rootNode.childNode(withName: "ball", recursively: true)
        ballNode.physicsBody?.contactTestBitMask = categoryTree
        selfieStickNode = scene.rootNode.childNode(withName: "selfieStick", recursively: true)
    }
    
    func setupSounds() {
        if let sawSound = SCNAudioSource(fileNamed: "chainsaw.wav"),  let jumpSound = SCNAudioSource(fileNamed: "jump.wav") {
            sawSound.load()
            jumpSound.load()
            sawSound.volume = 0.3
            jumpSound.volume = 0.4
            
            sounds["saw"] = sawSound
            sounds["jump"] = jumpSound
        }
        
        if let backgroundMusic = SCNAudioSource(fileNamed: "background.mp3") {
            backgroundMusic.volume = 0.1
            backgroundMusic.loops = true
            backgroundMusic.load()
            
            let musicPlayer = SCNAudioPlayer(source: backgroundMusic)
            ballNode.addAudioPlayer(musicPlayer)
        }
    }
    
    @objc
    func sceneViewTapped(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: sceneView)
        
        let hitResults = sceneView.hitTest(location, options: nil)
        
        if hitResults.count > 0, let result = hitResults.first, result.node.name == "ball", let jumpSound = sounds["jump"] {
            ballNode.runAction(SCNAction.playAudio(jumpSound, waitForCompletion: false))
            ballNode.physicsBody?.applyForce(SCNVector3(0, 4, -2), asImpulse: true)
        }
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

}

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let ball = ballNode.presentation
        let ballPosition = ball.position
        
        let targetPosition = SCNVector3(ballPosition.x, ballPosition.y + 5, ballPosition.z + 5)
        var cameraPosition = selfieStickNode.position
        
        let camDamping: Float = 0.3
        
        let xComponent = cameraPosition.x * (1 - camDamping) + targetPosition.x * camDamping
        let yComponent = cameraPosition.y * (1 - camDamping) + targetPosition.y * camDamping
        let zComponent = cameraPosition.z * (1 - camDamping) + targetPosition.z * camDamping
        
        cameraPosition = SCNVector3(xComponent, yComponent, zComponent)
        selfieStickNode.position = cameraPosition
        
        motion.getAccelerometerData { x, y, z in
            self.motionForce = SCNVector3(x * 0.05, 0, (y + 0.8) * -0.05)
        }
        
        ballNode.physicsBody?.velocity += motionForce
    }
}

extension GameViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        var contactNode: SCNNode!
        
        if contact.nodeA.name == "ball" {
            contactNode = contact.nodeB
        } else {
            contactNode = contact.nodeA
        }
        
        if contactNode.physicsBody?.categoryBitMask == categoryTree {
            contactNode.isHidden = true
            
            if let sawSound = sounds["saw"] {
                ballNode.runAction(SCNAction.playAudio(sawSound, waitForCompletion: false))
            }
            let waitAction = SCNAction.wait(duration: 15)
            let unhideAction = SCNAction.run { node in
                node.isHidden = false
            }
            let actionSequence = SCNAction.sequence([waitAction, unhideAction])
            contactNode.runAction(actionSequence)
        }
    }
}
