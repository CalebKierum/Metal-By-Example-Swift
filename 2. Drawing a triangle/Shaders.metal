#include <metal_stdlib>
using namespace metal;

/*
    Whenever [[]] is put it is an attribute qualifier that links it to it
        -position shows the position coord used for clipping etc
        -buffer(n) links the data to a buffer index from setVertexBuffer function
        -vertex_id links it to the vertex id of the vertex shader
        -stage_in says it is per fragment data
 */

//This vertex will be used to interpret the input of the vertex shader and
//the output of the vertex shader
struct Vertex
{
    float4 position [[position]];
    float4 color;
};

//Create a vertex shader
vertex Vertex vertex_main(device Vertex *vertices [[buffer(0)]], uint vid [[vertex_id]]) {
    //Simply grab the verticie from the buffer at the index vid
    return vertices[vid];
}

//Create a fragment shader
fragment float4 fragment_main(Vertex inVertex [[stage_in]]) {
    //Get the color of the invertex it will be interpolated
    return inVertex.color;
}
