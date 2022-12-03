struct Uniforms {
  halfwidth: f32,
  halfheight : f32
};

struct Camera {
    viewProjectionMatrix: mat4x4<f32>
};

struct Particle {
    position: vec3<f32>,
    lifetime: f32,
    velocity: vec3<f32>,
    rotation: vec3<f32>
}

struct Particles {
  particles : array<Particle>
};

@binding(0) @group(0) var<uniform> uniforms : Uniforms;
@binding(1) @group(0) var<uniform> camera: Camera;
@binding(0) @group(1) var<storage, read> particleBuffer : Particles;

struct VertexInput {
    @location(0) position : vec3<f32>,
    @location(1) lifetime :f32
};

struct VertexOutput {
    @builtin(position) position : vec4<f32>,
    @location(0) uv: vec2<f32>,
    @location(1) lifetime: f32
};

@vertex
fn main_instancing(vertexInput: VertexInput, @builtin(vertex_index) VertexIndex: u32) -> VertexOutput {
    return mainVert(vertexInput.position, vertexInput.lifetime, VertexIndex);
}


@vertex
fn main_vertex_pulling(@builtin(vertex_index) vertexIndex: u32) -> VertexOutput {
    let particleIdx = u32(vertexIndex/6);
    let quadIdx = vertexIndex % 6;
    let particle = particleBuffer.particles[particleIdx];

    return mainVert(particle.position, particle.lifetime, quadIdx);
}

fn mainVert(particlePos: vec3<f32>, particleLifetime: f32, quadVertIdx: u32) -> VertexOutput {
            var halfwidth = uniforms.halfwidth;
            var halfheight = uniforms.halfheight;

            var quadPos = array<vec2<f32>, 6>(
                vec2<f32>(-halfwidth, halfheight),   //tl
                vec2<f32>(-halfwidth, -halfheight),  //bl
                vec2<f32>(halfwidth, -halfheight),   //br

                vec2<f32>(halfwidth, -halfheight),   //br
                vec2<f32>(halfwidth, halfheight),    //tr
                vec2<f32>(-halfwidth, halfheight)    //tl
            );

            var uvs = array<vec2<f32>, 6>(
                vec2<f32>(0, 0),  //tl
                vec2<f32>(0, 1),  //bl
                vec2<f32>(1, 1),  //br

                vec2<f32>(1, 1),   //br
                vec2<f32>(1, 0),   //tr
                vec2<f32>(0, 0)    //tl
            );

            // the camera's up and right vector are required to make the quads always face the camera
            let cameraRight = vec3<f32>(camera.viewProjectionMatrix[0].x, camera.viewProjectionMatrix[1].x, camera.viewProjectionMatrix[2].x);
            let cameraUp = vec3<f32>(camera.viewProjectionMatrix[0].y, camera.viewProjectionMatrix[1].y, camera.viewProjectionMatrix[2].y);

            var posPlusQuad = particlePos;
            posPlusQuad = posPlusQuad + (cameraRight * quadPos[quadVertIdx].x);
            posPlusQuad = posPlusQuad + (cameraUp * quadPos[quadVertIdx].y);

            var output: VertexOutput;
            output.position = camera.viewProjectionMatrix * vec4<f32>(posPlusQuad,1.0);
            output.uv = uvs[quadVertIdx];
            output.lifetime = particleLifetime;

            if (output.lifetime <= 0) {
                output.position = vec4<f32>(100.0, 100.0, 10.0, 1.0); // discard expired particles
            }

            return output;
}
