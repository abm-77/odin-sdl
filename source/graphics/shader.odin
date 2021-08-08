package graphics

import gl "shared:odin-gl"
import "core:math"
import "core:math/linalg"

Shader :: u32;

shader_bind :: proc (shader: Shader) {
	gl.UseProgram(shader);
}
shader_set_bool :: proc (shader: Shader,  name: cstring, value: i32) {
    gl.Uniform1i(gl.GetUniformLocation(shader, name), value);
}

shader_set_samplerv :: proc (shader: Shader, name: cstring, n: i32, v: ^i32) {
    gl.Uniform1iv(gl.GetUniformLocation(shader, name), n, v);
}

shader_set_int :: proc (shader: Shader, name: cstring, value: i32) {
    gl.Uniform1i(gl.GetUniformLocation(shader, name), value);
}
shader_set_float :: proc (shader: Shader, name: cstring, value: f32) {
    gl.Uniform1f(gl.GetUniformLocation(shader, name), value);
}
shader_set_v2f :: proc (shader: Shader, name: cstring, x: f32, y: f32) {
    gl.Uniform2f(gl.GetUniformLocation(shader, name), x, y);
}
shader_set_v2fv :: proc (shader: Shader, name: cstring, v: ^f32) {
    gl.Uniform2fv(gl.GetUniformLocation(shader, name), 1, v);
}
shader_set_v3f :: proc (shader: Shader, name: cstring, x: f32, y: f32, z: f32) {
    gl.Uniform3f(gl.GetUniformLocation(shader, name), x, y, z);
}
shader_set_v3fv :: proc (shader: Shader, name: cstring, v: ^f32) {
    gl.Uniform3fv(gl.GetUniformLocation(shader, name), 1, v);
}
shader_set_v4f :: proc (shader: Shader, name: cstring , x: f32, y: f32, z: f32, w: f32) {
    gl.Uniform4f(gl.GetUniformLocation(shader, name), x, y, z, w);
}
shader_set_v4fv :: proc (shader: Shader, name: cstring, v: ^f32) {
    gl.Uniform4fv(gl.GetUniformLocation(shader, name), 1, v);
}
shader_set_vec3fv :: proc (shader: Shader, name: cstring, vec: ^f32) {
    gl.Uniform3fv(gl.GetUniformLocation(shader, name), 1, vec);
}
shader_set_mat4fv :: proc (shader : Shader, name: cstring, mat: ^f32) {
    gl.UniformMatrix4fv(gl.GetUniformLocation(shader, name), 1, gl.FALSE, mat);
}