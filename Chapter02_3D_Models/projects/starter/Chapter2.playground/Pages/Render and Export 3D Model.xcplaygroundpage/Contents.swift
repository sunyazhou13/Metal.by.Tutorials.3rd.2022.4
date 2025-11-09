import MetalKit
import PlaygroundSupport

guard let device = MTLCreateSystemDefaultDevice() else {
    fatalError("GPU is not supported")
}

let frame = CGRect(x: 0, y: 0, width: 600, height: 600)
let view = MTKView(frame: frame, device: device)
view.clearColor = MTLClearColor(red: 1,
                                green: 1, blue: 0.8, alpha: 1)

let allocator = MTKMeshBufferAllocator(device: device)
//let mdlMesh = MDLMesh(
//    sphereWithExtent: [0.75, 0.75, 0.75],
//    segments: [100, 100],
//    inwardNormals: false,
//    geometryType: .triangles,
//    allocator: allocator
//)
let mdlMesh = MDLMesh(
    coneWithExtent: [1,1,1],
    segments: [
        10,
        10
    ],
    inwardNormals: false,
    cap: true,
    geometryType: .triangles,
    allocator: allocator
)

let asset = MDLAsset()
asset.add(mdlMesh)
let fileExtension = "usda"
guard MDLAsset.canExportFileExtension(fileExtension) else {
    fatalError("Can't export a .\(fileExtension) format")
}

do {
    let url = playgroundSharedDataDirectory.appendingPathComponent(
        "primitive.\(fileExtension)")
    try asset.export(to: url)
} catch {
    fatalError("Error \(error.localizedDescription)")
}


let mesh = try MTKMesh(mesh: mdlMesh, device: device)

guard let commandQueue = device.makeCommandQueue() else {
    fatalError("Could not create a command queue")
}

let shader = """
#include <metal_stdlib>
using namespace metal;

struct VertexIn {
  float4 position [[attribute(0)]];
};

vertex float4 vertex_main(const VertexIn vertex_in [[stage_in]]) {
  return vertex_in.position;
}

fragment float4 fragment_main() {
  return float4(1, 0, 0, 1);
}
"""

let library = try device.makeLibrary(source: shader, options: nil)
let vertexFunction = library.makeFunction(name: "vertex_main")
let fragmentFunction = library.makeFunction(name: "fragment_main")

let pipelineDescriptor = MTLRenderPipelineDescriptor()
pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
pipelineDescriptor.vertexFunction = vertexFunction
pipelineDescriptor.fragmentFunction = fragmentFunction

pipelineDescriptor.vertexDescriptor =
    MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)

let pipelineState =
    try device.makeRenderPipelineState(descriptor: pipelineDescriptor)

guard let commandBuffer = commandQueue.makeCommandBuffer(),
      let renderPassDescriptor = view.currentRenderPassDescriptor,
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(
          descriptor: renderPassDescriptor)
else { fatalError() }

renderEncoder.setRenderPipelineState(pipelineState)

renderEncoder.setVertexBuffer(
    mesh.vertexBuffers[0].buffer, offset: 0, index: 0
)
renderEncoder.setTriangleFillMode(.lines)

guard let submesh = mesh.submeshes.first else {
    fatalError()
}

renderEncoder.drawIndexedPrimitives(
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








/**
 illusion 错觉
 manipulate 操控
 instructions 指令
 quads (four point polygons)四边形
 Diffuse → 漫反射
 Metallic → 金属度
 Roughness → 粗糙度

 
 - 三角形是任何可以在二维空间中绘制的多边形中顶点数量最少的。
 - 无论你如何移动三角形的顶点，这三个点始终在同一平面上。
 - 当你从任意顶点开始分割三角形时，它总是会变成两个三角形。
 • A triangle has the least number of points of any polygon that can be drawn in two
 dimensions.
 • No matter which way you move the points of a triangle, the three points will
 always be on the same plane.
 • When you divide a triangle starting from any vertex, it always becomes two
 triangles.
 
 
 
 */
