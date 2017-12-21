//Renderer is the object that actually does the render putting this code here helps keep things a bit cleaner

import Foundation
import Metal
import simd
import CoreGraphics
import QuartzCore

//We use vector_float4 because simd variables are more compatible with the gpu
struct MBEVertex {
    var position:vector_float4
    var color:vector_float4
}

class Renderer {
    
    //The vertices of the triangle
    var vertices:[MBEVertex] = [
        MBEVertex(position: vector_float4(0, 0.5, 0, 1), color: vector_float4(x: 1, y: 0, z: 0, w: 1)),
        MBEVertex(position: vector_float4(-0.5, -0.5, 0, 1), color: vector_float4(x: 0, y: 1, z: 0, w: 1)),
        MBEVertex(position: vector_float4(0.5, -0.5, 0, 1), color: vector_float4(x: 0, y: 0, z: 1, w: 1))]
    
    
    var device:MTLDevice?
    var vertexBuffer:MTLBuffer?
    var indexBuffer:MTLBuffer?
    var pipelineState:MTLRenderPipelineState?
    var commandQueue:MTLCommandQueue?
    
    init(device: MTLDevice?) {
        self.device = device
        makeBuffer()
        commandQueue = device?.makeCommandQueue()
        makePipeline()
    }
    
    //Make a buffer from the array
    func makeBuffer() {
        //This is the bit size of the data
        let dataSize = vertices.count * MemoryLayout.size(ofValue: vertices[0])
        vertexBuffer = device?.makeBuffer(bytes: vertices, length: dataSize, options: [MTLResourceOptions.storageModeShared])
    }
    
    //To create the pipeline we load a new library and to create a descriptor
    func makePipeline() {
        //The library gets a function from the shader
        let library = device?.makeDefaultLibrary()
        let vertexFunc = library?.makeFunction(name: "vertex_main")
        let fragmentFunc = library?.makeFunction(name: "fragment_main")
        
        //Set the pipeline descriptor with the new functions
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
        
        //This is not good coding... should be an optional type
        pipelineState = try! device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
    }
    
    func drawWith(drawable: CAMetalDrawable?, passDescriptor: MTLRenderPassDescriptor?) {
        //We arent doing any commands but we still need this so we can attach the descriptor and the drawable and commit
        let commandBuffer = commandQueue?.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: passDescriptor!)
        //Let the encode know about the state
        commandEncoder?.setRenderPipelineState(pipelineState!)
        //Set the vertex buffer at index 0 to the buffer
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        //Draw the triangles
        commandEncoder?.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: 3)
        
        commandEncoder?.endEncoding()
        
        if let drawOn = drawable {
            commandBuffer?.present(drawOn)
            commandBuffer?.commit()
        }
    }
}
