//
//  ViewController.swift
//  MetalIntro
//
//  Created by Marko Polietaiev on 02.03.2020.
//  Copyright © 2020 Marko Polietaiev. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let vertexData:[Float] =
      [0.0, 1.0, 0.0,
       -1.0, -1.0, 0.0,
       1.0, -1.0, 0.0]
    
    var device: MTLDevice!
    var metalLayer: CAMetalLayer!
    var vertexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var timer: CADisplayLink!
    
    override func viewDidLoad() {
      super.viewDidLoad()
      
      device = MTLCreateSystemDefaultDevice()
      
      metalLayer = CAMetalLayer()          // Create a new CAMetalLayer.
      metalLayer.device = device           // You must specify the MTLDevice the layer should use. You simply set this to the device you obtained earlier.
      metalLayer.pixelFormat = .bgra8Unorm // Set the pixel format to bgra8Unorm, which is a fancy way of saying “8 bytes for Blue, Green, Red and Alpha, in that order — with normalized values between 0 and 1.” This is one of only two possible formats to use for a CAMetalLayer, so normally you’d just leave this as-is.
      metalLayer.framebufferOnly = true    // Apple encourages you to set framebufferOnly to true for performance reasons unless you need to sample from the textures generated for this layer, or if you need to enable compute kernels on the layer drawable texture. Most of the time, you don’t need to do this.
      metalLayer.frame = view.layer.frame  // You set the frame of the layer to match the frame of the view.
      view.layer.addSublayer(metalLayer)   // Finally, you add the layer as a sublayer of the view’s main layer.
      
      let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0]) // You need to get the size of the vertex data in bytes. You do this by multiplying the size of the first element by the count of elements in the array.
      vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: []) // You call makeBuffer(bytes:length:options:) on the MTLDevice to create a new buffer on the GPU, passing in the data from the CPU. You pass an empty array for default configuration.

      
      // You can access any of the precompiled shaders included in your project through the MTLLibrary object you get by calling device.makeDefaultLibrary()!. Then, you can look up each shader by name.
      let defaultLibrary = device.makeDefaultLibrary()!
      let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
      let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
      
      // You set up your render pipeline configuration here. It contains the shaders that you want to use, as well as the pixel format for the color attachment — i.e., the output buffer that you’re rendering to, which is the CAMetalLayer itself.
      let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
      pipelineStateDescriptor.vertexFunction = vertexProgram
      pipelineStateDescriptor.fragmentFunction = fragmentProgram
      pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
      
      // Finally, you compile the pipeline configuration into a pipeline state that is efficient to use here on out.
      pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
      
      commandQueue = device.makeCommandQueue()
      
      timer = CADisplayLink(target: self, selector: #selector(gameloop))
      timer.add(to: RunLoop.main, forMode: .default)
    }
    
    func render() {
      guard let drawable = metalLayer?.nextDrawable() else { return }
      let renderPassDescriptor = MTLRenderPassDescriptor()
      renderPassDescriptor.colorAttachments[0].texture = drawable.texture
      renderPassDescriptor.colorAttachments[0].loadAction = .clear
      renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 55.0/255.0, alpha: 1.0)
      
      let commandBuffer = commandQueue.makeCommandBuffer()!
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
      renderEncoder.setRenderPipelineState(pipelineState)
      renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
      renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
      renderEncoder.endEncoding()
      
      commandBuffer.present(drawable)
      commandBuffer.commit()
    }
    
    @objc func gameloop() {
      autoreleasepool {
        self.render()
      }
    }
}

