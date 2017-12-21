/*
 Lesson 2: Drawing a triangle
 
 Lessons learned:
 Clear color does not require any bufferes or shaders
 Attribute qualifiers
 
 Steps:
 -In initialize
     1. Create Device
     2. Set Pixel Format with metal layer
     3. Create a buffer from the vertex data
     4. Create a pipeline descriptor from the functions from the Metal libraries
     5. Create a pipeline with the device.makePipelineState()
     6. Get a CADisplayLink to trigger an update function every frame
 -In draw
     7. Set a drawable
     8. Make renderPassDescriptor
     9. Make Command Queue
     10. Make Command Buffer
     11. Use descriptor to make encoder
     12. Command encoder needs to get the pipeline state
     13. Command encoder needs the vertex buffer
     14. Issue a draw command to the buffer
     15. Buffer creates a drawable and commits
 
 Objects Used:
 UIView: Has a layer that can be set to a core animation layer which can draw metal
 MTLDevice: Represents the GPU device and can be used to make things
 CAMetalLayer: A metal layer that can be used for UIView
 MTLDrawable: Hold texture can be drawn to or read from
 MTLRenderPassDescriptor: Describes a render pass... mostly what to do with the resources before and after and clear color
 MTLCommandQueue: Keeps a list of command buffers to be executed
 MTLCommandBuffer: Holds a list of commands
 MTLRenderCommandEncoder: Encodes instructions into the list of commands
 MBEVertex: Custom struct to hold a position and a color
 CADisplayLink: Links the code to metal frame updates
 MTLRenderPipelineState: Holds the pipeline state which includes attachments and shader functions
 
 Shader Insights:
 -Using simd vector_float4 makes passing from cpu to gpu easier
 -[[]] are attribute qualifiers that link fields to specefic expected things
 
 */

import UIKit
import Metal
import QuartzCore
import CoreGraphics
import simd

//We use vector_float4 because simd variables are more compatible with the gpu
struct MBEVertex {
    var position:vector_float4
    var color:vector_float4
}

class MBEMetalView: UIView {
    
    //The vertices of the triangle
    var vertices:[MBEVertex] = [
        MBEVertex(position: vector_float4(0, 0.5, 0, 1), color: vector_float4(x: 1, y: 0, z: 0, w: 1)),
        MBEVertex(position: vector_float4(-0.5, -0.5, 0, 1), color: vector_float4(x: 0, y: 1, z: 0, w: 1)),
        MBEVertex(position: vector_float4(0.5, -0.5, 0, 1), color: vector_float4(x: 0, y: 0, z: 1, w: 1))]
    
    var device:MTLDevice?
    var MTLLayer:CAMetalLayer?
    var buffer:MTLBuffer?
    var pipelineState:MTLRenderPipelineState?
    
    //This display link links us to the update of the layer
    var displayLink:CADisplayLink?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //Despite what the tutorial said we dont actually want to create anything as the frame is not yet known soon
    }
    
    //Grabs the MTLDevice. Beware this could be nil if device doesnt support metal
    func makeDevice() {
        device = MTLCreateSystemDefaultDevice()
    }
    
    //Sets of the metal layer and adds it as a sub to the view
    func setupMetalLayer() {
        MTLLayer = CAMetalLayer()
        MTLLayer?.device = device
        MTLLayer?.pixelFormat = MTLPixelFormat.bgra8Unorm
        MTLLayer?.framebufferOnly = true
        MTLLayer?.frame = frame
        layer.addSublayer(MTLLayer!)
    }
    
    //Make a buffer from the array
    func makeBuffer() {
        //This is the bit size of the data
        let dataSize = vertices.count * MemoryLayout.size(ofValue: vertices[0])
        buffer = device?.makeBuffer(bytes: vertices, length: dataSize, options: [MTLResourceOptions.storageModeShared])
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
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLLayer!.pixelFormat
        
        //This is not good coding... should be an optional type
        pipelineState = try! device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
    }
    
    //This function is when we know the frame and everything
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        makeDevice()
        setupMetalLayer()
        makeBuffer()
        makePipeline()
        
        redraw()
    }
    
    //The CADisplay Link lets us know when the core animation layer is updating
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if (superview != nil) {
            displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidFire))
            displayLink?.add(to: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        } else {
            displayLink?.invalidate()
            displayLink = nil
        }
    }
    
    //This gets triggered every frame by the display link
    @objc func displayLinkDidFire() {
        
        //If you wanted to animate the parameters do this with default buffer
        //vertices[0].position.x += 0.01
        //buffer?.contents().copyBytes(from: vertices, count: vertices.count * MemoryLayout<MBEVertex>.stride)
        
        redraw()
    }
    
    //Draws!
    func redraw() {
        //The layer gives us a drawable to render to the screen on... lets use it!
        let drawable = MTLLayer?.nextDrawable()
        let texture = drawable?.texture
        
        //Create a descriptor that says what to do wiht the texture
        let passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.colorAttachments[0].texture = texture
        passDescriptor.colorAttachments[0].loadAction = MTLLoadAction.clear
        passDescriptor.colorAttachments[0].storeAction = MTLStoreAction.store
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.85, 0.85, 0.85, 1)
        
        
        //We arent doing any commands but we still need this so we can attach the descriptor and the drawable and commit
        let commandQueue = device?.makeCommandQueue()
        let commandBuffer = commandQueue?.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: passDescriptor)
        
        //Let the encode know about the state
        commandEncoder?.setRenderPipelineState(pipelineState!)
        //Set the vertex buffer at index 0 to the buffer
        commandEncoder?.setVertexBuffer(buffer, offset: 0, index: 0)
        //Draw the triangles
        commandEncoder?.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: 3)
        commandEncoder?.endEncoding()
        
        if let drawOn = drawable {
            commandBuffer?.present(drawOn)
            commandBuffer?.commit()
        }
    }
    
}

