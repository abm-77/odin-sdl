package input

import sdl "shared:odin-sdl2"
import "core:fmt"
import "../../graphics"

NUM_SDLK_DOWN_EVENTS :: 322;

@(private)
InputState :: struct {
	prev_keys : [322]b32,
	curr_keys : [322]b32,

	mouse_position : [2]i32,
	mouse_left: b32,
	mouse_right: b32,
}

input_state: InputState;

update_input_state :: proc (event: sdl.Event) {
	using input_state;

	// mouse position
	mouse_x, mouse_y: i32;
	sdl.get_mouse_state(&mouse_x, &mouse_y);
	mouse_position = [2]i32{mouse_x, mouse_y};

	// keyboard state
	prev_keys = curr_keys;
	if event.type == sdl.Event_Type.Key_Down {
		curr_keys[event.key.keysym.sym] = true;
	}
	else if event.type == sdl.Event_Type.Key_Up {
		curr_keys[event.key.keysym.sym] = false;
	}
	else if (event.type == sdl.Event_Type.Mouse_Button_Down) {
		mouse_left = event.button.button == u8(sdl.Mousecode.Left);
		mouse_right = event.button.button == u8(sdl.Mousecode.Right);
	}
	else if (event.type == sdl.Event_Type.Mouse_Button_Up) {
		mouse_left = !(event.button.button == u8(sdl.Mousecode.Left));
		mouse_right = !(event.button.button == u8(sdl.Mousecode.Right));
	}
}

mouse_world_position :: proc () -> ([2]f32) {
	using input_state;
	return [2]f32{f32(mouse_position.x), f32(mouse_position.y)};
}

mouse_screen_position :: proc (camera: ^graphics.Camera) -> ([2]f32) {
	using input_state;
	return [2]f32{f32(mouse_position.x) + camera.position.x, f32(mouse_position.y) + camera.position.y};
}

get_key_down :: proc (key: sdl.Keycode) -> (b32) {
	using input_state;
	return curr_keys[key];
}

// doesn't work?
get_key_press :: proc (key: sdl.Keycode) -> (b32) {
	using input_state;
	return curr_keys[key] && !prev_keys[key];
}

get_key_up :: proc (key: sdl.Keycode) -> (b32) {
	using input_state;
	return !curr_keys[key] && prev_keys[key];
}

MouseButton :: enum {
	LEFT,
	RIGHT,
}

get_mouse_button :: proc (b: MouseButton) -> (b32) {
	using input_state;

	result : b32 = false;
	if b == MouseButton.LEFT {
		result = mouse_left;
	}
	else if b == MouseButton.RIGHT{
		result = mouse_right;
	}

	return result;
}