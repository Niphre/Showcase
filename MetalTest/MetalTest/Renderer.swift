//
//  Renderer.swift
//  MetalTest
//
//  Created by Isaac Snediker-Morscheck on 9/22/19.


import Foundation
import MetalKit
import ModelIO
import simd

struct VertexUniforms {
    var modelMatrix: float4x4
    var projectionViewMatrix: float4x4
    var normalMatrix: float3x3
}

struct FragmentUniforms {
    var cameraPosition = float3(0, 0, 0)
    var ambientColor = float3(0, 0, 0)
    var specularColor = float3(1, 1, 1)
    var specularPower = Float(50)
    var light0 = Light()
    var light1 = Light()
    var light2 = Light()
}

class Renderer: NSObject, MTKViewDelegate {
    
    let device: MTLDevice
    let mtkView: MTKView
    let commandQueue: MTLCommandQueue
    let depthStencilState: MTLDepthStencilState
    let samplerState: MTLSamplerState
    
    let scene: Scene
    
    var meshes: [MTKMesh] = []
    
    var time: Float = 0
    var cameraWorldPosition = float3(0, 0, 0)
    var viewMatrix = matrix_identity_float4x4
    var projectionMatrix = matrix_identity_float4x4
    
    var vertexDescriptor: MDLVertexDescriptor!
    var renderPipeline: MTLRenderPipelineState!
    var baseColorTexture: MTLTexture?
    
   
    
    func update(_ view: MTKView) {
        time += 1 / Float(mtkView.preferredFramesPerSecond)
        
        cameraWorldPosition = float3(0, 0.25, 1)
        viewMatrix = float4x4(translationBy: -cameraWorldPosition)
        
        let aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
        projectionMatrix = float4x4(perspectiveProjectionFov: Float.pi/3, aspectRatio: aspectRatio, nearZ: 0.1, farZ: 100)
        
        let angle = -time
        scene.rootNode.modelMatrix = float4x4(rotationAbout: float3(0, 1, 0), by: angle) *  float4x4(scaleBy: 4)
        
        
        if let spot = scene.nodeNamed("Spot") {
            spot.modelMatrix = float4x4(scaleBy: 0.075) * float4x4(translationBy: float3(0.25, 0.75, 1)) * float4x4(rotationAbout: float3(0, 1, 0), by: 90)
        }
        
    }
    
    static func buildScene(device: MTLDevice, vertexDescriptor: MDLVertexDescriptor) -> Scene {
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let textureLoader = MTKTextureLoader(device: device)
        let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : true]
               
        let scene = Scene()
        
        scene.ambientColor = float3(0.1, 0.1, 0.1)
        let light0 = Light(worldPosition: float3( 2,  2, 2), color: float3(1, 0, 0))
        let light1 = Light(worldPosition: float3(-2,  2, 2), color: float3(0, 1, 0))
        let light2 = Light(worldPosition: float3( 0, -2, 2), color: float3(0, 0, 1))
        scene.lights = [ light0, light1, light2 ]
               
        //model 1
        let bunny = Node(name: "Bunny")
        
        let modelURL = Bundle.main.url(forResource: "Stanford_Bunny", withExtension: "obj")!
        let asset = MDLAsset(url: modelURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        bunny.mesh = try! MTKMesh.newMeshes(asset: asset, device: device).metalKitMeshes.first
        bunny.materal.baseColorTexture = try? textureLoader.newTexture(name: "GridTile_Color", scaleFactor: 1.0, bundle: nil, options: options)
        bunny.materal.specularPower = 150
        bunny.materal.specularColor = float3(1.0, 1.0, 1.0)
        
        scene.rootNode.children.append(bunny)
        
        
        //model 2
        let spot = Node(name:"Spot")
        let spotBaseColorTexture = try? textureLoader.newTexture(name: "Spot_Color", scaleFactor: 1.0, bundle: nil, options: options)
        
        spot.materal.baseColorTexture = spotBaseColorTexture
        spot.materal.specularPower = 50
        spot.materal.specularColor = float3(0.7, 0.7, 0.7)
        
        let spotURL = Bundle.main.url(forResource: "spot_triangulated", withExtension: "obj")!
        let spotAsset = MDLAsset(url: spotURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        spot.mesh = try! MTKMesh.newMeshes(asset: spotAsset, device: device).metalKitMeshes.first!
        
        scene.rootNode.children.append(spot)
        
        return scene
    }

    
    //sets up important render info, loads recources and build pipelines
    init(view: MTKView, device: MTLDevice) {
        self.mtkView = view
        self.device = device
        commandQueue = device.makeCommandQueue()!
        vertexDescriptor = Renderer.buildVertexDescriptor()
        renderPipeline = Renderer.buildPipeline(device: device, view: view, vertexDescriptor: vertexDescriptor)
        depthStencilState = Renderer.buildDepthStencilState(device: device)
        samplerState = Renderer.buildSamplerState(device: device)
        scene = Renderer.buildScene(device: device, vertexDescriptor: vertexDescriptor)
        super.init()
        
    }
    
    static func buildVertexDescriptor () -> MDLVertexDescriptor {
         let vertexDescriptor = MDLVertexDescriptor()
         vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
         vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                                    format: .float3,
                                                                    offset: MemoryLayout<Float>.size * 3,
                                                                    bufferIndex: 0)
         vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                                                                    format: .float2,
                                                                    offset: MemoryLayout<Float>.size * 6,
                                                                    bufferIndex: 0)
         vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
         return vertexDescriptor
     }

    static func buildDepthStencilState(device: MTLDevice) -> MTLDepthStencilState {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        return device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
    }
    
    static func buildSamplerState(device: MTLDevice) -> MTLSamplerState {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.normalizedCoordinates = true
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.maxAnisotropy = 8
        return device.makeSamplerState(descriptor: samplerDescriptor)!
    }
    
    static func buildPipeline(device: MTLDevice, view: MTKView, vertexDescriptor: MDLVertexDescriptor) -> MTLRenderPipelineState {
        //create defualt library
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not load defualt library until main bundle")
        }
        //load shader functions
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        //set up pipeline state
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        
        let mtlVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        
        do {
            return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create render pipeline state object: \(error)")
        }
    }
    
    
    
        
    
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        update(view)
                 
        let commandBuffer = commandQueue.makeCommandBuffer()!
        if let renderPassDescriptor = view.currentRenderPassDescriptor, let drawable = view.currentDrawable {
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            commandEncoder.setFrontFacing(.counterClockwise)
            commandEncoder.setCullMode(.back)
            commandEncoder.setDepthStencilState(depthStencilState)
            commandEncoder.setRenderPipelineState(renderPipeline)
            commandEncoder.setFragmentSamplerState(samplerState, index: 0)
            
            drawNodeRecursive(scene.rootNode, parentTransform: matrix_identity_float4x4, commandEncoder: commandEncoder)
            
            commandEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()

        }
        
    }
    
    func drawNodeRecursive(_ node: Node, parentTransform: float4x4, commandEncoder: MTLRenderCommandEncoder) {
        let modelMatrix = parentTransform * node.modelMatrix
        if let mesh = node.mesh, let baseColorTexture = node.materal.baseColorTexture {
            
            //Vertex Uniforms
            let viewProjectionMatrix = projectionMatrix * viewMatrix
            var vertexUniforms = VertexUniforms(modelMatrix: modelMatrix, projectionViewMatrix: viewProjectionMatrix, normalMatrix: modelMatrix.normalMatrix)
            commandEncoder.setVertexBytes(&vertexUniforms, length: MemoryLayout<VertexUniforms>.size, index: 1)
            
            //Fragment Uniforms
            var fragmentUniforms = FragmentUniforms(cameraPosition: cameraWorldPosition, ambientColor: scene.ambientColor, specularColor: node.materal.specularColor, specularPower: node.materal.specularPower, light0: scene.lights[0], light1: scene.lights[1], light2: scene.lights[2])
            commandEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.size, index: 0)
            
            commandEncoder.setFragmentTexture(baseColorTexture, index: 0)
            
            let vertexBuffer = mesh.vertexBuffers.first!
            commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
            
            for submesh in mesh.submeshes {
                let indexBuffer = submesh.indexBuffer
                commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: indexBuffer.buffer, indexBufferOffset: indexBuffer.offset)
            }
        }
        
        for child in node.children {
            drawNodeRecursive(child, parentTransform: modelMatrix, commandEncoder: commandEncoder)
        }
    }

   
    
}
