//
//  VectorOperations.swift
//  BallGame
//
//  Created by Mauro Arantes on 24/11/2023.
//

import Foundation
import SceneKit

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(x:left.x + right.x, y: left.y + right.y, z: left.z + right.z)
}


func +=( left: inout SCNVector3, right: SCNVector3) {
    left = left + right
}
