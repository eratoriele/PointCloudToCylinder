//
//  ViewController.swift
//  imageDetectionReality
//
//  Created by macos on 15.02.2020.
//  Copyright © 2020 macos. All rights reserved.
//

import UIKit
import RealityKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    // The points in the point coud
    struct Point {
        var x = float_t.init(bitPattern: 0)
        var y = float_t.init(bitPattern: 0)
        var z = float_t.init(bitPattern: 0)
    }
    // Array of Points
    var pointCloud = [Point]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arView.session.delegate = self
        
        arView.automaticallyConfigureSession = false
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        configuration.isLightEstimationEnabled = true
        
        guard let trackedImages = ARReferenceImage.referenceImages(inGroupNamed: "trackImages", bundle: Bundle.main) else {
            return
        }

        configuration.detectionImages = trackedImages
        configuration.maximumNumberOfTrackedImages = 1
        
        arView.session.run(configuration)
        
        arView.debugOptions = [
            .showFeaturePoints,
            .showAnchorOrigins,
            .showWorldOrigin
        ]
        
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                           action: #selector(handleTap(recognizer:))))
        
    }
    
    @objc
    func handleTap(recognizer: UITapGestureRecognizer) {
        var pointmin = Point(x: float_t(UInt32.min), y: float_t(UInt32.min), z: float_t(UInt32.min))
        var pointmax = Point(x: float_t(UInt32.max), y: float_t(UInt32.max), z: float_t(UInt32.max))
        
        for i in 0...pointCloud.count {
            // Get the minimum corner
            pointmin.x = float_t.minimum(pointmin.x, pointCloud[i].x)
            pointmin.y = float_t.minimum(pointmin.y, pointCloud[i].y)
            pointmin.z = float_t.minimum(pointmin.z, pointCloud[i].z)
            
            // Get the maximum corner
            pointmax.x = float_t.maximum(pointmax.x, pointCloud[i].x)
            pointmax.y = float_t.maximum(pointmax.y, pointCloud[i].y)
            pointmax.z = float_t.maximum(pointmax.z, pointCloud[i].z)
        }
        
        // Corner points
        let a = Point(x: pointmin.x, y: pointmin.y, z: pointmin.z)
        let b = Point(x: pointmin.x, y: pointmin.y, z: pointmax.z)
        let c = Point(x: pointmax.x, y: pointmin.y, z: pointmax.z)
        let d = Point(x: pointmax.x, y: pointmin.y, z: pointmin.z)
        let e = Point(x: pointmax.x, y: pointmax.y, z: pointmax.z)
        let f = Point(x: pointmin.x, y: pointmax.y, z: pointmax.z)
        let g = Point(x: pointmin.x, y: pointmax.y, z: pointmin.z)
        let h = Point(x: pointmax.x, y: pointmax.y, z: pointmin.z)
        
        //Cylinder axis line going through centerPointOfCylinder and centerOfAPlane point
        var center = Point(x: (pointmax.x + pointmin.x) / 2,
                           y: (pointmax.y + pointmin.y) / 2,
                           z: (pointmax.z + pointmin.z) / 2);
        
        var centerPointOfAPlane = Point(x: (e.x + g.x) / 2,
                                        y: (e.y + g.y) / 2,
                                        z: (e.z + g.z) / 2);
        
        var centerPointOfOppPlane = Point(x: (a.x + c.x) / 2,
                                          y: (a.y + c.y) / 2,
                                          z: (a.z + c.z) / 2);
        
        //Take max diagonal from plane
        var diameter = float_t.maximum(sqrtf((a.x - c.x)*(a.x - c.x) + (a.y - c.y)*(a.y - c.y) + (a.z - c.z)*(a.z - c.z)), sqrtf((b.x - d.x)*(b.x - d.x) + (b.y - d.y)*(b.y - d.y) + (b.z - d.z)*(b.z - d.z)))
        
        var height = abs(pointmax.y - pointmin.y)
        
        // Why isnt there a cylinder Mesh????
        //let mesh = MeshResource.generatebox
    }
}


extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {

        for vect in frame.rawFeaturePoints?.points ?? [] {
            
            let tempPoint = Point(x: vect.x, y: vect.y, z: vect.z)
            pointCloud.append(tempPoint)
            
            // If the point is not already in the array
            if pointCloud.contains(where: { (poi) -> Bool in
                if poi.x == tempPoint.x && poi.y == tempPoint.y && poi.z == tempPoint.z {
                    return false
                }
                else {
                    return true
                }
            }) {
                pointCloud.append(tempPoint)
            }
        }
        
    }
}
