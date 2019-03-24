//
//  MLController.swift
//  draw
//
//  Created by Anirudh Natarajan on 3/15/19.
//  Copyright © 2019 Anirudh Natarajan. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision
import CoreML

public class MLController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    // classification initialization
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let modelUrl = #fileLiteral(resourceName: "Numbers_Custom.mlmodel")
            let compiledUrl = try MLModel.compileModel(at: modelUrl)
            let model = try VNCoreMLModel(for: try MLModel(contentsOf: compiledUrl))
            
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    // setup UI variables
    var mainButton: UIButton!
    var playButton: UIButton!
    var blankView: UIView!
    var timeLabel: UILabel!
    
    var backgroundView = UIView()
    var contentView = UIView()
    var titleLabel = UILabel()
    var separatorLineView = UIView()
    var predictionLabel = UILabel()
    var predictionImage = UIImageView()
    var predictionImageBW = UIImage()
    let shrinkConstant:CGFloat = 1/4
    
    let session = ARSession()
    var sceneView : ARSCNView!
    
    var previousPoint: SCNVector3?
    var lineColor: UIColor = UIColor(red: 208.0/255, green: 0.0/255, blue: 0.0/255, alpha: 1)
    public var totalTime = 3
    var timeLeft: Int!
    var timer: Timer!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        // setup intro scene
        
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
        // setup AR scene and popup
        setupAR()
        initializePopup()
        
        // setup UI for drawing
        let size: CGFloat = 100.0
        mainButton = UIButton(type: .custom)
        mainButton.frame = CGRect(x: view.frame.width/2 - size/2, y: view.frame.height-size*1.5, width: size, height: size)
        mainButton.setImage(UIImage.init(named: "paint1"), for: .normal)
        mainButton.tag = 0
        mainButton.addTarget(self, action:#selector(self.switchCase), for: .touchDown)
        self.view.addSubview(mainButton)
        
        let size2:CGFloat = 200.0
        timeLabel = UILabel(frame: CGRect(x: view.frame.width/2 - size2/2, y: size2/5, width: size2, height: size2*0.6))
        timeLabel.text = "\(totalTime)"
        timeLabel.textColor = .black
        timeLabel.textAlignment = .center
        timeLabel.font = UIFont.systemFont(ofSize: 80)
        self.view.addSubview(timeLabel)
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
    
    @objc func switchCase(sender:UIButton) {
        if mainButton.tag == 0 {
            // start timer and painting state
            mainButton.tag = 1
            timeLeft = totalTime
            timeLabel.text = "\(timeLeft!)"
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(countDown), userInfo: nil, repeats: true)
        } else if mainButton.tag == 2 {
            // switch to pre-drawing state
            var image = sceneView.snapshot()
            
            // convert image
            image = convertToBW(image: image).toUIImage()!
            predictionImageBW = image
//            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
            // classify image
            classify(for: image)
            
            mainButton.tag = 0
            mainButton.setImage(UIImage.init(named: "paint1"), for: .normal)
        }
    }
    
    func processClassifications(for request: VNRequest, error: Error?) {
        // do something with prediction
        
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.showPopup(title: "Prediction", prediction: "I think the number you drew is ... I'm not sure actually. Try again!", image: self.predictionImageBW)
                return
            }
            // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
            let classifications = results as! [VNClassificationObservation]
            
            if classifications.isEmpty {
                self.showPopup(title: "Prediction", prediction: "I think the number you drew is ... I'm not sure actually. Try again!", image: self.predictionImageBW)
            } else {
                // Display top classifications ranked by confidence in the UI.
                self.showPopup(title: "Prediction", prediction: "I think the number you drew is \(classifications.first?.identifier ?? "... I'm not sure actually. Try again")!", image: self.predictionImageBW)
            }
        }
    }
    
    func classify(for image: UIImage) {
        // send image to classification
        
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation!)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    func showPopup(title:String, prediction:String, image: UIImage) {
        // animate bringing up the popup and screenshot
        
        titleLabel.text = title
        predictionLabel.text = prediction
        predictionImage.image = image
        
        self.backgroundView.alpha = 0
        self.contentView.center = CGPoint(x: self.view.center.x, y: self.view.frame.height + self.contentView.frame.height)
        self.predictionImage.frame = self.view.frame
        
        let smallFrame = CGRect(x: self.view.frame.width - self.view.frame.width*self.shrinkConstant - 10, y: self.view.frame.height - self.view.frame.height*self.shrinkConstant - 10, width: self.view.frame.width*self.shrinkConstant, height: self.view.frame.height*self.shrinkConstant)
        
        view.addSubview(backgroundView)
        view.addSubview(contentView)
        view.addSubview(predictionImage)
        
        UIView.animate(withDuration: 0.75, animations: {
            self.backgroundView.alpha = 0.66
            self.predictionImage.frame = smallFrame
        })
        UIView.animate(withDuration: 0.75, delay: 0.45, usingSpringWithDamping: 0.5, initialSpringVelocity: 9, options: UIView.AnimationOptions(rawValue: 0), animations: {
            self.contentView.center = self.view.center
        }, completion: { (completed) in
            
        })
    }
    
    func dismissPopup(){
        // animate dismissal of popup and screenshot
        
        UIView.animate(withDuration: 0.33, animations: {
            self.backgroundView.alpha = 0
        }, completion: { (completed) in
            
        })
        UIView.animate(withDuration: 0.33, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 10, options: UIView.AnimationOptions(rawValue: 0), animations: {
            self.contentView.center = CGPoint(x: self.view.center.x, y: self.view.frame.height + self.contentView.frame.height/2)
            self.predictionImage.center = CGPoint(x: self.predictionImage.center.x, y: self.view.frame.height + self.predictionImage.frame.height/2)
        }, completion: { (completed) in
            self.backgroundView.removeFromSuperview()
            self.contentView.removeFromSuperview()
            self.predictionImage.removeFromSuperview()
        })
    }
    
    func initializePopup() {
        // setup UI for popup
        
        backgroundView.frame = view.frame
        backgroundView.backgroundColor = .black
        backgroundView.alpha = 0.6
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedOnBackgroundView)))
        
        let contentViewWidth = view.frame.width*1/2
        
        titleLabel = UILabel(frame: CGRect(x: 8, y: 8, width: contentViewWidth - 16, height: 45))
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 30)
        contentView.addSubview(titleLabel)
        
        separatorLineView = UIView()
        separatorLineView.frame.origin = CGPoint(x: 0, y: titleLabel.frame.height + 8)
        separatorLineView.frame.size = CGSize(width: contentViewWidth, height: 1)
        separatorLineView.backgroundColor = UIColor.groupTableViewBackground
        contentView.addSubview(separatorLineView)
        
        predictionLabel = UILabel(frame: CGRect(x: contentViewWidth/2-(contentViewWidth - 80)/2, y: separatorLineView.frame.height + titleLabel.frame.height + 10, width: contentViewWidth - 80, height: view.frame.height/8))
        predictionLabel.textAlignment = .center
        predictionLabel.numberOfLines = 10
        predictionLabel.font = UIFont.systemFont(ofSize: 20)
        contentView.addSubview(predictionLabel)
        
        let contentViewHeight = titleLabel.frame.height + separatorLineView.frame.height + predictionLabel.frame.height + 20
        
        contentView.frame.origin = view.center
        contentView.frame.size = CGSize(width: contentViewWidth, height: contentViewHeight)
        contentView.backgroundColor = UIColor(red: 211.0/255, green: 228.0/255, blue: 237.0/255, alpha: 1)
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        
        predictionImage = UIImageView(frame: view.frame)
        predictionImage.layer.cornerRadius = 10
        predictionImage.clipsToBounds = true
    }
    
    @objc func didTappedOnBackgroundView(){
        // remove the popup
        clearScene()
        dismissPopup()
    }
    
    @objc func countDown() {
        // count down the timer
        timeLeft -= 1
        timeLabel.text = "\(timeLeft!)"
        if timeLeft <= 0 {
            // stop drawing and start classification
            timer.invalidate()
            mainButton.setImage(UIImage.init(named: "camera"), for: .normal)
            mainButton.tag = 2
        }
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
        if mainButton.isHighlighted && mainButton.tag==1{
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
    
    private func clearScene() {
        // erase all drawings
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
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
