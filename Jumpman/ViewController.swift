//
//  ViewController.swift
//  Jumpman
//
//  Created by Developer on 10/3/17.
//  Copyright © 2017 JwitApps. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum PhysicsCategory: Int {
    case none = 0
    case character = 1
    case pad = 2
}

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    let scene = GameScene()
    
    var gameArea: ARPlaneAnchor!
    var gameNode: SCNNode!
    
    var character: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        setup(scene: scene)
        
        sceneView.scene = scene
    }
    
    func setup(scene: GameScene) {
        scene.physicsWorld.contactDelegate = self
        scene.physicsWorld.timeStep = 1/1000.0
        scene.physicsWorld.gravity.y /= 2.0
        
        sceneView.debugOptions = SCNDebugOptions.showPhysicsShapes
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let character = character {
            var position = sceneView.pointOfView!.position
            position.x += 0.1 * sceneView.pointOfView!.eulerAngles.x
            position.y += 0.1 * sceneView.pointOfView!.eulerAngles.y
            position.z += 0.1 * sceneView.pointOfView!.eulerAngles.z
            character.position = position
        }
        
        if let physics = character?.physicsBody {
            if physics.velocity.y < 0 {
                character.physicsBody?.collisionBitMask = PhysicsCategory.pad.rawValue
            }
        }
        
        if let first = scene.pads.first {
            if first.presentation.position.y < 0 {
                
                let fadeOut = SCNAction.fadeOut(duration: 0.2)
                let remove = SCNAction.removeFromParentNode()
                first.runAction(SCNAction.sequence([fadeOut, remove]))
                
                scene.pads.removeFirst()
                
                if let last = scene.pads.last {
                    let lastY = last.presentation.position.y
                    
                    let position = SCNVector3(x: gameArea.center.x,
                                              y: 0.2 + lastY,
                                              z: gameArea.center.z)
                    let pad = generatePad(atPosition: position)
                    gameNode.addChildNode(pad)
                    scene.pads.append(pad)
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                node.childNodes.forEach { $0.removeFromParentNode() }
                
                self.startGame(on: planeAnchor, node: node)
            }
        }
    }
    
    func startGame(on anchor: ARPlaneAnchor, node: SCNNode) {
        gameArea = anchor
        gameNode = node
        
        let planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x),
                                     height: CGFloat(anchor.extent.z))
        
        let plane = SCNNode(geometry: planeGeometry)
        plane.geometry?.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.3)
        
        plane.transform = SCNMatrix4MakeRotation(-.pi / 2.0, 1.0, 0.0, 0.0)
        
        plane.position = SCNVector3(x: anchor.center.x,
                                    y: 0,
                                    z: anchor.center.z)
        node.addChildNode(plane)
        
        srand48(Int(Date().timeIntervalSinceReferenceDate))
        for i in 1...3 {
            let position = SCNVector3(x: anchor.center.x,
                                      y: 0.2 * Float(i),
                                      z: anchor.center.z)
            let pad = generatePad(atPosition: position)
            node.addChildNode(pad)
            scene.pads.append(pad)
        }
        
        let character = createCharacter(atPosition: .init(x: 0, y: 0, z: 0))
        node.addChildNode(character)
        self.character = character
    }
    
    func createCharacter(atPosition position: SCNVector3) -> SCNNode {
        let sphere = SCNSphere(radius: 0.05)
        sphere.firstMaterial?.diffuse.contents = UIColor.red
        
        let node = SCNNode(geometry: sphere)
        node.position = position
        
//        let square = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
//        let shape = SCNPhysicsShape(geometry: square, options: nil)
        let physics = SCNPhysicsBody(type: .dynamic, shape: nil)
        physics.friction = 0
        physics.damping = 0
        physics.categoryBitMask = PhysicsCategory.character.rawValue
        physics.contactTestBitMask = PhysicsCategory.pad.rawValue
        physics.collisionBitMask = PhysicsCategory.pad.rawValue
        physics.isAffectedByGravity = false
        node.physicsBody = physics
        return node
    }
    
    func generatePad(atPosition position: SCNVector3) -> SCNNode {
//        let box = SCNBox(width: 0.2, height: 0.02, length: 0.2, chamferRadius: 0)
        let box = SCNBox(width: CGFloat(0.05 + drand48() * (0.3 - 0.05)), height: 0.02, length: CGFloat(0.05 + drand48() * (0.3 - 0.05)), chamferRadius: 0)
//
        box.firstMaterial?.diffuse.contents = UIColor.purple
        
        let pad = SCNNode(geometry: box)
        pad.position = position
        
        let physics = SCNPhysicsBody(type: .dynamic, shape: nil)
        physics.categoryBitMask = PhysicsCategory.pad.rawValue
        physics.contactTestBitMask = PhysicsCategory.character.rawValue
        physics.collisionBitMask = 0
        physics.isAffectedByGravity = false
        physics.friction = 0
        physics.damping = 0
        physics.allowsResting = true
        physics.velocity.y = -0.1
        pad.physicsBody = physics
        return pad
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {
            character.physicsBody?.velocity = .init(0, 2, 0)
            character.physicsBody?.isAffectedByGravity = true
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodes = [contact.nodeA, contact.nodeB]
        let bodies = nodes.map{$0.physicsBody!}
        
        func node(with category: PhysicsCategory) -> SCNNode? {
            return nodes.filter{$0.physicsBody?.categoryBitMask==category.rawValue}.first
        }
        
        if let character = node(with: PhysicsCategory.character),
            let pad = node(with: PhysicsCategory.pad) {
            
            guard let physics = character.physicsBody else { return }
            let velocity = physics.velocity
            
            let isAbovePad = character.presentation.position.y > pad.presentation.position.y
            
            if velocity.y < 0 && isAbovePad {
                character.physicsBody?.velocity = .init(0, 2, 0)
                character.physicsBody?.collisionBitMask = 0
            }
        }
    }
}
