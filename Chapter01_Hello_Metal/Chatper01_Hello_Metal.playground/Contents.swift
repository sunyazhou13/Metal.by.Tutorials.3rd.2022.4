import PlaygroundSupport
import MetalKit


guard let device = MTLCreateSystemDefaultDevice() else {
    fatalError("GPU is not supported!")
}

let frame = CGRect(x: 0, y: 0, width: 600, height: 600)
let view = MTKView(frame: frame, device: device)
view.clearColor = MTLClearColor(red: 1, green: 1, blue: 0.8, alpha: 1)

//The allocator manages the memory for the mesh data.
let allocator = MTKMeshBufferAllocator(device: device)
//Model I/O creates a sphere with the specified size and returns an MDLMesh with all the vertex information in data buffers
let mdlMesh = MDLMesh(
    sphereWithExtent: [0.75, 0.75, 0.75],
    segments: [100, 100],
    inwardNormals: false,
    geometryType: .triangles,
    allocator: allocator
)
//For Metal to be able to use the mesh, you convert it from a Model I/O mesh to a MetalKit mesh.
let mesh = try MTKMesh(mesh: mdlMesh, device: device)

guard let commandQueue = device.makeCommandQueue() else {
    fatalError("Could not create a command queue!")
}

let shader = """
#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];  
};

vertex float4 vertex_main(const VertexIn vertex_in [[stage_in]])
{
    return vertex_in.position;
}

fragment float4 fragment_main() {
    return float4(0, 0.4, 0.21, 1);
}
"""

let library = try device.makeLibrary(source: shader, options: nil)
let vertexFunction = library.makeFunction(name: "vertex_main")
let fragmentFunction = library.makeFunction(name: "fragment_main")


let pipelineDescriptor = MTLRenderPipelineDescriptor()
pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
pipelineDescriptor.vertexFunction = vertexFunction
pipelineDescriptor.fragmentFunction = fragmentFunction

pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(
    mesh.vertexDescriptor
)

let pipelineState = try device.makeRenderPipelineState(
    descriptor: pipelineDescriptor
)

guard let commandBuffer = commandQueue.makeCommandBuffer(),
      let renderPassDescriptor = view.currentRenderPassDescriptor,
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(
        descriptor: renderPassDescriptor
      ) else {
    fatalError()
}

renderEncoder.setRenderPipelineState(pipelineState)
//rennderEncode <-- commandBuffer <-- commandQueue
//pipelineState <-- pipelineDescriptor
//renderEncode 设置 pipelineState

//偏移量是缓冲区中顶点信息开始的位置。索引是GPU顶点着色器函数定位此缓冲区的方式。
renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)


guard let submesh = mesh.submeshes.first else {
    fatalError()
}

//draw call
renderEncoder
    .drawIndexedPrimitives(
        type: .triangle,
        indexCount: submesh.indexCount,
        indexType: submesh.indexType,
        indexBuffer: submesh.indexBuffer.buffer,
        indexBufferOffset: 0
    )

renderEncoder.endEncoding()


guard let drawable = view.currentDrawable else {
    fatalError()
}
commandBuffer.present(drawable)
commandBuffer.commit()

PlaygroundPage.current.liveView = view

//--------------------------------------------------//
/*
 单词
 
 cylinder 圆柱体
 torus 环面 (面包圈形状的旋转曲面)
 manipulate 操作,控制
 instruct 吩咐
 */
