/*
 Lesson 1: Drawing a blank screen
 
 Lessons learned:
 Clear color does not require any bufferes or shaders
 
 Steps:
 -In initialize
    1. Create Device
    2. Set Pixel Format in a new Metal layer
 -In draw
    3. Set a drawable
    4. Make renderPassDescriptor
    5. Make Command Queue
    6. Make Command Buffer
    7. Use descriptor to make encoder
    8. Buffer creates a drawable and commits
 
 Objects Used:
 UIView: Has a layer that can be set to a core animation layer which can draw metal
 MTLDevice: Represents the GPU device and can be used to make things
 CAMetalLayer: A metal layer that can be used for UIView
 MTLDrawable: Hold texture can be drawn to or read from
 MTLRenderPassDescriptor: Describes a render pass... mostly what to do with the resources before and after and clear color
 MTLCommandQueue: Keeps a list of command buffers to be executed
 MTLCommandBuffer: Holds a list of commands
 MTLRenderCommandEncoder: Encodes instructions into the list of commands
 
 */

import UIKit
import Metal
import QuartzCore
import CoreGraphics

class MBEMetalView: UIView {
    
    var device:MTLDevice?
    var MTLLayer:CAMetalLayer?
    
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
    
    //This function is when we know the frame and everything
    override func didMoveToWindow() {
        makeDevice()
        setupMetalLayer()
        
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
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 0, 1)
        
        
        //We arent doing any commands but we still need this so we can attach the descriptor and the drawable and commit
        let commandQueue = device?.makeCommandQueue()
        let commandBuffer = commandQueue?.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: passDescriptor)
        commandEncoder?.endEncoding()
        
        if let drawOn = drawable {
            commandBuffer?.present(drawOn)
            commandBuffer?.commit()
        }
    }
    
}

