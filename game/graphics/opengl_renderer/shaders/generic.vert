#version 430 core

layout (location = 0) in vec3 position_in;
layout (location = 1) in vec4 rgba_in;
layout (location = 2) in vec2 tex_coord_in;
layout (location = 3) in uvec4 byte_info;

uniform float mat_32;
uniform vec3 fog_constants;
uniform vec4 scale;
uniform float mat_23;
uniform float mat_33;
uniform vec4 hvdf_offset;

out vec2 tex_coord;

out vec4 fragment_color;
out float fog;

out flat uvec2 tex_info;

void main() {
    // lq.xy vf22, 0(vi10)          texture load?
    // lq_buffer(Mask::xy, vu.vf22, vu.vi10);

    // lq.xyz vf16, 2(vi10)         vertex load
    // lq_buffer(Mask::xyz, gen.vtx_load0, vu.vi10 + 2);

    // mtir vi02, vf22.x            grab s coordinate of texture
    // vu.vi02 = vu.vf22.x_as_u16();

    // mulaw.xyzw ACC, vf11, vf00   matrix multiply W
    // vu.acc.mula(Mask::xyzw, gen.mat3, vu.vf00.w());
    vec4 transformed;

    // maddax.xyzw ACC, vf08, vf16  matrix multiply X
    // vu.acc.madda(Mask::xyzw, gen.mat0, gen.vtx_load0.x());
    transformed.xyz = position_in * scale.xyz;
    transformed.z += mat_32;
    transformed.w = mat_23 * position_in.z + mat_33;

    transformed *= -1; // todo?


    // div Q, vf01.x, vf12.w        perspective divide
    // vu.Q = gen.fog.x() / gen.vtx_p0.w();
    float Q = fog_constants.x / transformed.w;

    float fog1 = -transformed.w + hvdf_offset.w;
    float fog2 = min(fog1, fog_constants.z);
    float fog3 = max(fog2, fog_constants.y);
    fog = 1 - (fog3/256);

    // itof12.xyz vf18, vf22        texture int to float
    // vu.vf18.itof12(Mask::xyz, vu.vf22);
    tex_coord = tex_coord_in / 4096.f; // TODO, more and wrong.

    // mul.xyz vf12, vf12, Q        persepective divide
    // gen.vtx_p0.mul(Mask::xyz, gen.vtx_p0, vu.Q);
    transformed.xyz *= Q;

    // mul.xyz vf18, vf18, Q        texture perspective divide
    // vu.vf18.mul(Mask::xyz, vu.vf18, vu.Q);

    // add.xyzw vf12, vf12, vf04    apply hvdf
    // gen.vtx_p0.add(Mask::xyzw, gen.vtx_p0, gen.hvdf_off);
    transformed.xyz += hvdf_offset.xyz;

    // correct xy offset
    transformed.xy -= (2048.);

    // correct z scale
    transformed.z /= (8388608);
    transformed.z -= 1;

    // correct xy scale
    transformed.x /= (256);
    transformed.y /= -(128);

    // hack
    transformed.xyz *= transformed.w;

    gl_Position = transformed;
    // scissoring area adjust
    gl_Position.y *= 512.0/448.0;

    fragment_color = vec4(rgba_in.x, rgba_in.y, rgba_in.z, rgba_in.w * 2.);
    tex_info = byte_info.xy;
}