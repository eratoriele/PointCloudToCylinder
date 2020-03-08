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

// The points in the point coud
struct Point {
    var x:Float = 0
    var y:Float = 0
    var z:Float = 0
}

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    // Array of Points
    var pointCloud = [Point]()
    var chosenPointCloud = [Point]()

    let pointtouchRange:CGFloat = 100
    let chosenCloudLimit = 150
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arView.session.delegate = self
        
        arView.automaticallyConfigureSession = false
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        configuration.isLightEstimationEnabled = true
        
        /*guard let trackedImages = ARReferenceImage.referenceImages(inGroupNamed: "trackImages", bundle: Bundle.main) else {
            return
        }*/

        //configuration.detectionImages = trackedImages
        configuration.maximumNumberOfTrackedImages = 1
        
        arView.session.run(configuration)
        
        arView.debugOptions = [
            //.showFeaturePoints,
            //.showAnchorOrigins,
            //.showWorldOrigin
        ]
        
        //arView.addGestureRecognizer(UIRotationGestureRecognizer(target: self,
         //                                                       action: #selector(handleTap(recognizer:))))
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else { return }
        let currentPoint = touch.location(in: arView)
        
        // Get all feature points in the current frame
        let fp = self.arView.session.currentFrame?.rawFeaturePoints?.points
        guard let count = fp?.count else { return }
        
        // Create a material
        let material = SimpleMaterial(color: SimpleMaterial.Color.red, isMetallic: false)
        
        let anchorEntity = AnchorEntity()
        // Loop over them and check if any exist near our touch location
        // If a point exists in our range, let's draw a sphere at that feature point
        for i in 0..<count {
            let point = vector3(fp![i].x, fp![i].y, fp![i].z)
            let projection = arView.project(point)
            if (projection!.x < (currentPoint.x + pointtouchRange) && projection!.x > (currentPoint.x - pointtouchRange) &&
                projection!.y < (currentPoint.y + pointtouchRange) && projection!.y > (currentPoint.y - pointtouchRange) ) {
                let ballShape = MeshResource.generateSphere(radius: 0.001)
                let ballModel = ModelEntity(mesh: ballShape, materials: [material])
                
                anchorEntity.addChild(ballModel)
                ballModel.position = point
                
                self.chosenPointCloud.append(Point(x: point.x, y: point.y, z: point.z))
            }
        }
        
        arView.scene.addAnchor(anchorEntity)
        if (self.chosenPointCloud.count > chosenCloudLimit) {
            getCylinderData(pointCloud: self.chosenPointCloud)
        }
        else {
            print("Not Enough points. Current points: ", self.chosenPointCloud.count, "Needed: ", chosenCloudLimit)
        }
    }
    
    /*
    func removeDuplicates(arr: [Point]) -> [Point] {
        var uniqueArr = [Point]()
        
        for i in 0..<arr.count {
            if !uniqueArr.contains(where: { (poi) -> Bool in
                if (poi.x == arr[i].x && poi.y == arr[i].y && poi.z == arr[i].z) {
                    return true
                }
                return false
            }) {
                uniqueArr.append(Point(x: arr[i].x, y: arr[i].y, z: arr[i].z))
            }
            print("Point ", i, " of ", arr.count, " has been placed. ", uniqueArr.count)
        }
        
        return uniqueArr
    }*/
    
    func getCylinderData(pointCloud: [Point]) {
        
        var pointmin = pointCloud[0]
        var pointmax = pointCloud[0]
        
        for i in 1...pointCloud.count - 1 {
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
        let _ = Point(x: pointmax.x, y: pointmax.y, z: pointmax.z)
        let _ = Point(x: pointmin.x, y: pointmax.y, z: pointmax.z)
        let _ = Point(x: pointmin.x, y: pointmax.y, z: pointmin.z)
        let _ = Point(x: pointmax.x, y: pointmax.y, z: pointmin.z)
        
        // center of the circle on the bottom side
        let center = Point(x: (pointmax.x + pointmin.x) / 2,
                           y: pointmin.y,
                           z: (pointmax.z + pointmin.z) / 2);
        
        //Take max diagonal from plane
        let radius = float_t.maximum(sqrtf((a.x - c.x)*(a.x - c.x) + (a.y - c.y)*(a.y - c.y)), sqrtf((b.x - d.x)*(b.x - d.x) + (b.y - d.y)*(b.y - d.y)))
        
        let height = abs(pointmax.y - pointmin.y)

        print("Center: ", center, "\nDiameter: ", radius, "\nHeight: ", height, "\nMinMax: ", pointmin, pointmax, pointCloud.count)
        
        //let mesh = MeshResource.generateBox(width: radius, height: height, depth: radius)
        let material = SimpleMaterial(color: SimpleMaterial.Color.green.withAlphaComponent(0.7), isMetallic: false)
        let mesh = MeshResource.generateBox(width: radius, height: height, depth: radius)

        let model = ModelEntity(mesh: mesh, materials: [material])
        
        let anchorEntity = AnchorEntity()
        anchorEntity.addChild(model)
        
        model.position.x = center.x
        model.position.y = center.y + ((pointmax.y - pointmin.y) / 2)
        model.position.z = center.z
        
        arView.scene.addAnchor(anchorEntity)
        
        chosenPointCloud.removeAll()
    }
}


extension ViewController: ARSessionDelegate {
    /*
    func session(_ session: ARSession, didUpdate frame: ARFrame) {

        for vect in frame.rawFeaturePoints?.points ?? [] {
            
            pointCloud.append(Point(x: vect.x, y: vect.y, z: vect.z))
        }
        
    }*/
}
