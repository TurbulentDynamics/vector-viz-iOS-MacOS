//
//  ViewController.swift
//  HelloMetalMac
//

import Cocoa
import simd

class MacSceneViewController: MetalViewController, MetalViewControllerDelegate {
    
    var worldModelMatrix:float4x4!
    var vectorsObject: Vectors!
    
    let panSensivity:Float = 5.0
    var lastLocation: CGPoint!
    
    @IBOutlet weak var minusButton: NSButton!
    @IBOutlet weak var plusButton: NSButton!
    
    var previousMultiplier: Float!
    var multiplier: Float! {
        didSet {
            multiplierLabel.stringValue = String(format: "multiplier = %.2f", multiplier)
        }
    }
    
    var newFile: Bool! = true
    
    @IBOutlet weak var multiplierLabel: NSTextField!
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        worldModelMatrix = float4x4()
        metalViewControllerDelegate = self
        
        multiplier = 0.05
        vectorsObject = Vectors(device: device, commandQ: commandQueue, textureLoader: textureLoader, multiplier: 0)

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "OpenFile"), object: nil, queue: .current) { notification in
            if let contents = notification.object as? String {
                self.newFile = true

                IncomingData.shared.readDataFromFile(contents: contents)
                self.previousMultiplier = 0
                self.multiplier = 0.05
                self.setNewMultiplier()
                
                self.vectorsObject.scale = 1
                self.worldModelMatrix.translate(0.0, y: 0.0, z: -1)
                self.worldModelMatrix.rotateAroundX(0, y: float4x4.degrees(toRad: 90), z: 0.0)
            }
        }
    }

    override func viewDidAppear() {
        if let url = Bundle.main.url(forResource: "inputVectors", withExtension: "vvt") {
            let string = try? String.init(contentsOf: url)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "OpenFile"), object: string)
        }
    }
    
    override func scrollWheel(with event: NSEvent) {
        vectorsObject.scale -= Float(event.deltaY) * vectorsObject.scale
    }
    
    override func mouseDown(with event: NSEvent) {
        lastLocation = event.locationInWindow
    }
    
    override func mouseDragged(with event: NSEvent) {
        let xDelta = Float((lastLocation.x - event.locationInWindow.x)/self.view.bounds.width) * panSensivity
        let yDelta = Float((lastLocation.y - event.locationInWindow.y)/self.view.bounds.height) * panSensivity
        
        vectorsObject.rotationY -= xDelta
        vectorsObject.rotationZ -= yDelta
        
        lastLocation = event.locationInWindow
    }
    
    override func rightMouseDown(with event: NSEvent) {
        lastLocation = event.locationInWindow
    }

    override func rightMouseDragged(with event: NSEvent) {
        let xDelta = Float((lastLocation.x - event.locationInWindow.x)/self.view.bounds.width)
        let yDelta = Float((lastLocation.y - event.locationInWindow.y)/self.view.bounds.height)
        
        vectorsObject.positionZ -= xDelta
        vectorsObject.positionY -= yDelta
        
        lastLocation = event.locationInWindow
    }
    
    @IBAction func buttonChangeMultiplier(_ sender: NSButton) {
        multiplier = multiplier + (sender.tag == 1 ? 0.01 : -0.01)
        multiplier = multiplier <= 0 ? 0 : multiplier
        if multiplier > 0 { self.setNewMultiplier() }
    }
    
    func setNewMultiplier() {
        if previousMultiplier != multiplier {
            self.plusButton.isEnabled = false
            self.minusButton.isEnabled = false
            
            DispatchQueue.global().async {
                self.previousMultiplier = self.multiplier
                let old = self.vectorsObject!
                self.vectorsObject = Vectors(device: self.device, commandQ: self.commandQueue, textureLoader: self.textureLoader, multiplier: self.multiplier)
                if self.newFile == true { // new file
                    self.newFile = false
                    self.vectorsObject.scale = 1
                    self.vectorsObject.rotationX = 0
                    self.vectorsObject.rotationY = 0
                    self.vectorsObject.rotationZ = 0
                    self.vectorsObject.positionX = 0
                    self.vectorsObject.positionY = 0
                    self.vectorsObject.positionZ = 0
                } else {
                    self.vectorsObject.scale = old.scale
                    self.vectorsObject.rotationX = old.rotationX
                    self.vectorsObject.rotationY = old.rotationY
                    self.vectorsObject.rotationZ = old.rotationZ
                    self.vectorsObject.positionX = old.positionX
                    self.vectorsObject.positionY = old.positionY
                    self.vectorsObject.positionZ = old.positionZ
                }
                
                DispatchQueue.main.async {
                    self.plusButton.isEnabled = true
                    self.minusButton.isEnabled = true
                }
            }
        }
    }
    
    
    //MARK: - MetalViewControllerDelegate
    func renderObjects(_ drawable:CAMetalDrawable) {
        
        vectorsObject.render(commandQueue, pipelineState: pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix, clearColor: nil)
    }
    
    func updateLogic(_ timeSinceLastUpdate: CFTimeInterval) {
        vectorsObject.updateWithDelta(timeSinceLastUpdate)
    }
    
}
