//
//  Materal.swift
//  MetalTest
//
//  Created by Isaac Snediker-Morscheck on 10/7/19.


import Foundation
import simd
import MetalKit

class Materal {
    var specularColor = float3(1, 1, 1)
    var specularPower = Float(50)
    var baseColorTexture: MTLTexture?
}
