package graphics

import "core:math"
import "core:math/linalg"


Viewport :: struct {
	x, y: f32,
	width, height: f32,
}

Camera :: struct {
	position: linalg.Vector3f32,
	view_matrix: linalg.Matrix4f32,
}

camera_update_view_matrix :: proc (using camera: ^Camera) {
	using linalg;
	view_matrix = matrix4_look_at_f32(position, position + Vector3f32{0, 0, -1}, Vector3f32{0, 1, 0});
}

camera_move :: proc (using camera: ^Camera, delta_x: f32, delta_y: f32) {
	position.x += delta_x;
	position.y += delta_y;
	camera_update_view_matrix(camera);
}

camera_set_position :: proc (using camera: ^Camera, new_x: f32, new_y: f32) {
	position.x = new_x;
	position.y = new_y;
	camera_update_view_matrix(camera);
}