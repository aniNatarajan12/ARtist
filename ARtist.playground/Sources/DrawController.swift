//
//  Dr
//  draw
//
//  Created by Anirudh Natarajan on 3/22/19.
//  Copyright © 2019 Anirudh Natarajan. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

public class DrawController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    // setup UI variables
    var mainButton: UIButton!
    var playButton: UIButton!
    var blankView: UIView!
    var clearButton: UIButton!
    var saveButton: UIButton!
    var saveImage = UIImageView()
    
    var color1Button: UIButton!
    var color2Button: UIButton!
    var color3Button: UIButton!
    let color1 = UIColor(red: 208.0/255, green: 0.0/255, blue: 0.0/255, alpha: 1)
    let color2 = UIColor(red: 19.0/255, green: 111.0/255, blue: 99.0/255, alpha: 1)
    let color3 = UIColor(red: 255.0/255, green: 186.0/255, blue: 8.0/255, alpha: 1)
    
    let session = ARSession()
    var sceneView : ARSCNView!
    
    var previousPoint: SCNVector3?
    var lineColor: UIColor!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // start the intro scene
        setupIntro()
    }
    
    private func setupIntro() {
        // setup the introduction UI
        
        blankView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        blankView.backgroundColor = .white
        self.view.addSubview(blankView)
        
        blankView.translatesAutoresizingMaskIntoConstraints = false
        blankView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        blankView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        blankView.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
        blankView.heightAnchor.constraint(equalToConstant: view.frame.height).isActive = true
        
        let size: CGFloat = 300.0
        playButton = UIButton(type: .custom)
        playButton.frame = CGRect(x: view.frame.width/2 - size/2, y: view.frame.height/2-size/2, width: size, height: size)
        playButton.setImage(UIImage.init(named: "power"), for: .normal)
        playButton.addTarget(self, action:#selector(self.playGame), for: .touchUpInside)
        self.view.addSubview(playButton)
        
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: size).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: size).isActive = true
    }
    
    @objc func playGame(sender:UIButton) {
        UIView.animate(withDuration: 1.0, delay: 0.0, options: .curveEaseOut, animations: {
            // fade out the white view
            self.blankView.backgroundColor = .black
        }) { (finished) in
            self.blankView.removeFromSuperview()
            self.playButton.removeFromSuperview()
            //setup drawing
            self.setupDraw()
        }
    }
    
    private func setupDraw() {
        // setup AR scene
        setupAR()
        
        //set color
        lineColor = color1
        
        // setup the AR scene UI
        var size: CGFloat = 100.0
        mainButton = UIButton(type: .custom)
        mainButton.frame = CGRect(x: view.frame.width/2 - size/2, y: view.frame.height-size*1.5, width: size, height: size)
        mainButton.setImage(UIImage.init(named: "paint1"), for: .normal)
        self.view.addSubview(mainButton)
        
        size = 75
        clearButton = UIButton(type: .custom)
        clearButton.setImage(UIImage.init(named: "clear"), for: .normal)
        clearButton.frame = CGRect(x: size/2, y: view.frame.height-size*1.5, width: size, height: size)
        clearButton.addTarget(self, action:#selector(clearScene), for: .touchDown)
        self.view.addSubview(clearButton)
        
        saveButton = UIButton(type: .custom)
        saveButton.setImage(UIImage.init(named: "save"), for: .normal)
        saveButton.frame = CGRect(x: view.frame.width - size - 20, y: 20, width: size, height: size)
        saveButton.addTarget(self, action:#selector(savePicture), for: .touchDown)
        self.view.addSubview(saveButton)
        
        size = 45
        color3Button = UIButton(type: .custom)
        color3Button.frame = CGRect(x: view.frame.width - size/2 - size, y: view.frame.height-size*1.5, width: size, height: size)
        color3Button.setImage(UIImage.init(named: "color3"), for: .normal)
        color3Button.layer.cornerRadius = 40
        color3Button.addTarget(self, action:#selector(color3Pressed), for: .touchDown)
        
        color2Button = UIButton(type: .custom)
        color2Button.frame = CGRect(x: view.frame.width - size/2 - size*2 - 10, y: view.frame.height-size*1.5, width: size, height: size)
        color2Button.setImage(UIImage.init(named: "color2"), for: .normal)
        color2Button.layer.cornerRadius = 40
        color2Button.addTarget(self, action:#selector(color2Pressed), for: .touchDown)
        
        color1Button = UIButton(type: .custom)
        color1Button.frame = CGRect(x: view.frame.width - size/2 - size*3 - 20, y: view.frame.height-size*1.5, width: size, height: size)
        color1Button.setImage(UIImage.init(named: "color1"), for: .normal)
        color1Button.layer.cornerRadius = 40
        color1Button.addTarget(self, action:#selector(color1Pressed), for: .touchDown)
        color1Button.isEnabled = false
        
        self.view.addSubview(color1Button)
        self.view.addSubview(color2Button)
        self.view.addSubview(color3Button)
    }
    
    @objc private func clearScene() {
        // erase all drawings
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
    }
    
    @objc private func savePicture() {
        let image = sceneView.snapshot()
        saveImage = UIImageView(frame: view.frame)
        saveImage.layer.cornerRadius = 10
        saveImage.clipsToBounds = true
        // save image to camera roll
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        //add animations
        animateSave(image: image)
    }
    
    func animateSave(image: UIImage){
        // set screenshot equal to screen
        saveImage.image = image
        saveImage.frame = view.frame
        view.addSubview(saveImage)
        
        // shrink the screenshot to the bottom right and remove
        let shrinkConstant:CGFloat = 1/4
        let smallFrame = CGRect(x: self.view.frame.width - self.view.frame.width*shrinkConstant - 10, y: self.view.frame.height - self.view.frame.height*shrinkConstant - 10, width: self.view.frame.width*shrinkConstant, height: self.view.frame.height*shrinkConstant)
        
        UIView.animate(withDuration: 0.75, animations: {
            self.saveImage.frame = smallFrame
        })
        UIView.animate(withDuration: 0.33, delay: 0.75, usingSpringWithDamping: 1, initialSpringVelocity: 10, options: UIView.AnimationOptions(rawValue: 0), animations: {
            self.saveImage.center = CGPoint(x: self.saveImage.center.x, y: self.view.frame.height + self.saveImage.frame.height/2)
        }, completion: { (completed) in
            self.saveImage.removeFromSuperview()
        })
    }
    
    // Changing the color depending on what button is pressed
    @objc private func color1Pressed() {
        color1Button.isHighlighted = true
        color1Button.isEnabled = false
        color2Button.isHighlighted = false
        color2Button.isEnabled = true
        color3Button.isHighlighted = false
        color3Button.isEnabled = true
        lineColor = color1
        mainButton.setImage(UIImage.init(named: "paint1"), for: .normal)
    }
    
    @objc private func color2Pressed() {
        color1Button.isHighlighted = false
        color1Button.isEnabled = true
        color2Button.isHighlighted = true
        color2Button.isEnabled = false
        color3Button.isHighlighted = false
        color3Button.isEnabled = true
        lineColor = color2
        mainButton.setImage(UIImage.init(named: "paint2"), for: .normal)
    }
    
    @objc private func color3Pressed() {
        color1Button.isHighlighted = false
        color1Button.isEnabled = true
        color2Button.isHighlighted = false
        color2Button.isEnabled = true
        color3Button.isHighlighted = true
        color3Button.isEnabled = false
        lineColor = color3
        mainButton.setImage(UIImage.init(named: "paint3"), for: .normal)
    }
    
    private func setupAR() {
        // setup the AR stuff
        
        sceneView = ARSCNView(frame: CGRect(x: 0.0, y: 0.0, width: 475.0, height: 740.0))
        
        sceneView.scene = SCNScene()
        
        let config = ARWorldTrackingConfiguration()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session = session
        
        sceneView.session.delegate = self
        
        self.view = sceneView
        sceneView.session.run(config)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        guard let pointOfView = sceneView.pointOfView else { return }
        
        // setup current position
        let mat = pointOfView.transform
        let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
        let currentPosition = pointOfView.position + (dir * 0.1)
        
        // add another node to create a line
        if mainButton.isHighlighted{
            if let previousPoint = previousPoint {
                let twoPointsNode = SCNNode()
                _ = twoPointsNode.buildLineInTwoPointsWithRotation(
                    from: previousPoint,
                    to: currentPosition,
                    radius: 0.002,
                    color: lineColor)
                sceneView.scene.rootNode.addChildNode(twoPointsNode)
            }
        }
        previousPoint = currentPosition
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        print("error launching ARSession: \(error.localizedDescription)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        print("session was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        print("session was interrupted ended")
    }
    
}
