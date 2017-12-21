/*
 Lesson 2: Drawing a triangle REFACTORED
 
 Refactoring was to move some of the code into a separate renderer class before proceeding.
 Certain things should go in the renderer and other things should stay.
 
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

class View: UIView {
    

    var MTLLayer:CAMetalLayer?
    
    //This display link links us to the update of the layer
    var displayLink:CADisplayLink?
    
    //These are the things the view actually needs to keep track of
    var clearColor:MTLClearColor?
    var drawable:CAMetalDrawable?
    var device:MTLDevice?
    
    //This will handle the rendering of the scene!
    var renderer:Renderer
    
    required init?(coder aDecoder: NSCoder) {
        //The renderer actually handles all of the rendering
        device = MTLCreateSystemDefaultDevice()
        renderer = Renderer(device: device)
        super.init(coder: aDecoder)
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
        super.didMoveToWindow()
        setupMetalLayer()
        
        displayLinkDidFire()
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
        
        //The layer gives us a drawable to render to the screen on... lets use it!
        clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1)
        drawable = MTLLayer?.nextDrawable()
        renderer.drawWith(drawable: drawable, passDescriptor: currentRenderPassDecriptor())
    }
    
    
    func currentRenderPassDecriptor() -> MTLRenderPassDescriptor {
        //Create a descriptor that says what to do wiht the texture
        let passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.colorAttachments[0].texture = drawable?.texture
        passDescriptor.colorAttachments[0].loadAction = MTLLoadAction.clear
        passDescriptor.colorAttachments[0].storeAction = MTLStoreAction.store
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.85, 0.85, 0.85, 1)
        return passDescriptor
    }
    
}

