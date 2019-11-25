//
//  ViewController.swift
//  Visual Signal
//
//  Created by Vergil Choi on 2018/12/29.
//  Copyright © 2018 Vergil Choi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit



class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var strengthLabel: UILabel!
    
    var cameraTransform = simd_float4x4()
    var timer: Timer!
    var currentNode: SCNNode?
    var currentLabelNode: SCNNode?
    var link: CADisplayLink?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/main.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { _ in
            self.strengthLabel.text = String(format: "  WiFi Strength: %.02f%%  ", self.wifiStrength() * 100)
        })
        timer.fire()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
        timer.invalidate()
    }
    
    
    
    fileprivate func getColor(_ strength: Double) -> UIColor {
        let max:CGFloat = 90.0
        let one:CGFloat = (255+255)/60.0
        let val:CGFloat = max * CGFloat(strength)
        var red:CGFloat = 0, green:CGFloat = 0, blue:CGFloat = 0
        if(val < 30){
            red = 1.0
        }else if (val>=30 && val < 60){
            red = 1.0
            green = (255 - (val - 30) * one) / 255
        }
        else{
            red = one * val / 255
            green = 1.0
        }
        
        return UIColor(displayP3Red: red, green: green, blue: blue, alpha: 1)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let strength = wifiStrength()
        let sphere = SCNSphere(radius: 0.01)
        sphere.firstMaterial?.diffuse.contents = getColor(strength)
        currentLabelNode = TextNode(text: String(format: "%.02f%%", strength * 100), font: "AvenirNext-Regular", colour: getColor(strength))
        
        currentNode = SCNNode(geometry: sphere)
        updatePositionAndOrientationOf(currentNode!, withPosition: SCNVector3(0, 0, -0.15), relativeTo: sceneView.pointOfView!)
        updatePositionAndOrientationOf(currentLabelNode!, withPosition: SCNVector3(0, 0.02, -0.15), relativeTo: sceneView.pointOfView!)
        sceneView.scene.rootNode.addChildNode(currentNode!)
        sceneView.scene.rootNode.addChildNode(currentLabelNode!)
        
        link = CADisplayLink(target: self, selector: #selector(scalingNode))
        link?.add(to: RunLoop.main, forMode: .common)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        link?.invalidate()
    }
    
    @objc func scalingNode() {
        if let node = currentNode {
            node.scale = SCNVector3(node.scale.x + 0.02, node.scale.y + 0.02, node.scale.z + 0.02)
        }
        if let node = currentLabelNode {
            node.scale = SCNVector3(node.scale.x + 0.02, node.scale.y + 0.02, node.scale.z + 0.02)
            node.position.y += 0.0002
        }
    }
    
    func updatePositionAndOrientationOf(_ node: SCNNode, withPosition position: SCNVector3, relativeTo referenceNode: SCNNode) {
        let referenceNodeTransform = matrix_float4x4(referenceNode.transform)
        
        // Setup a translation matrix with the desired position
        var translationMatrix = matrix_identity_float4x4
        translationMatrix.columns.3.x = position.x
        translationMatrix.columns.3.y = position.y
        translationMatrix.columns.3.z = position.z
        
        // Combine the configured translation matrix with the referenceNode's transform to get the desired position AND orientation
        let updatedTransform = matrix_multiply(referenceNodeTransform, translationMatrix)
        node.transform = SCNMatrix4(updatedTransform)
    }
    
    func wifiStrength() -> Double {
        let statusBarManager = view.window?.windowScene?.statusBarManager
        let localStatusBar = statusBarManager?.perform(Selector(("createLocalStatusBar")))?.takeUnretainedValue() as? UIView
        let statusBar = localStatusBar?.perform(Selector(("statusBar")))?.takeUnretainedValue() as? UIView
        let _statusBar = statusBar?.value(forKey: "_statusBar") as? UIView
        let currentData = _statusBar?.value(forKey: "currentData") as? NSObject

        // Cellular signal
        let cellularEntry = currentData?.value(forKey: "cellularEntry") as? NSObject
        let signalBars = cellularEntry?.value(forKey: "displayValue") as? Int
        let barToDbm = [0: -90, 1: -75, 2: -60, 3:-45, 4: -30]


        //Wifi Signal
//        let wifiEntry = currentData?.value(forKey: "wifiEntry") as? NSObject
//        let signalBars = wifiEntry?.value(forKey: "displayValue") as? Int
//        let barToDbm = [0: -90, 1: -70, 2: -50, 3: -30]

        let dBm = barToDbm[signalBars ?? 0] ?? -90

        var strength = (Double(dBm) + 90.0) / 60.0
        if strength > 1 {
            strength = 1
        }
        return strength

//        let app = UIApplication.shared
//        let subviews = ((app.value(forKey: "statusBar") as! NSObject).value(forKey: "foregroundView") as! UIView).subviews
//        var dataNetworkItemView: UIView?
//
//        for subview in subviews {
//            if subview.isKind(of: NSClassFromString("UIStatusBarDataNetworkItemView")!) {
//                dataNetworkItemView = subview
//                break
//            }
//        }
//
//        let dBm = (dataNetworkItemView!.value(forKey: "wifiStrengthRaw") as! NSNumber).intValue
//        var strength = (Double(dBm) + 90.0) / 60.0
//        if strength > 1 {
//            strength = 1
//        }
//        return strength
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

// https://stackoverflow.com/questions/50678671/setting-up-the-orientation-of-3d-text-in-arkit-application
class TextNode: SCNNode{
    
    var textGeometry: SCNText!
    
    /// Creates An SCNText Geometry
    ///
    /// - Parameters:
    ///   - text: String (The Text To Be Displayed)
    ///   - depth: Optional CGFloat (Defaults To 1)
    ///   - font: UIFont
    ///   - textSize: Optional CGFloat (Defaults To 3)
    ///   - colour: UIColor
    init(text: String, depth: CGFloat = 0.01, font: String = "Helvatica", textSize: CGFloat = 1, colour: UIColor) {
        
        super.init()
        
        //1. Create A Billboard Constraint So Our Text Always Faces The Camera
        let constraints = SCNBillboardConstraint()
        
        //2. Create An SCNNode To Hold Out Text
        let node = SCNNode()
        let max, min: SCNVector3
        let tx, ty, tz: Float
        
        //3. Set Our Free Axes
        constraints.freeAxes = .Y
        
        //4. Create Our Text Geometry
        textGeometry = SCNText(string: text, extrusionDepth: depth)
        
        //5. Set The Flatness To Zero (This Makes The Text Look Smoother)
        textGeometry.flatness = 0
        
        //6. Set The Alignment Mode Of The Text
        textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        
        //7. Set Our Text Colour & Apply The Font
        textGeometry.firstMaterial?.diffuse.contents = colour
        textGeometry.firstMaterial?.isDoubleSided = true
        textGeometry.font = UIFont(name: font, size: textSize)
        
        //8. Position & Scale Our Node
        max = textGeometry.boundingBox.max
        min = textGeometry.boundingBox.min
        
        tx = (max.x - min.x) / 2.0
        ty = min.y
        tz = Float(depth) / 2.0
        
        node.geometry = textGeometry
        node.scale = SCNVector3(0.01, 0.01, 0.1)
        node.pivot = SCNMatrix4MakeTranslation(tx, ty, tz)
        
        self.addChildNode(node)
        
        self.constraints = [constraints]
        
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
