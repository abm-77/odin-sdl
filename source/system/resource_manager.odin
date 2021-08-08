package system

import "core:fmt"

import gl "shared:odin-gl"
import stbi "shared:odin-stbi"

import "../graphics"

image_dir :: "resources/graphics/images/";
shader_dir :: "resources/graphics/shaders/";

ResourceManager :: struct {
	shaders: map[string]graphics.Shader,
	textures: map[string]graphics.Texture2D,
}

// must be cstring bc stbi uses cstring...
rm_image_dir :: proc ($image: string) -> (cstring) {
	return cstring(image_dir + image);
}
rm_shader_dir :: proc ($shader: string) -> (string) {
	return shader_dir + shader;
}

rm_create :: proc () -> (manager: ResourceManager){
	manager.shaders = make (map[string]graphics.Shader);	
	manager.textures = make (map[string]graphics.Texture2D);	
	return manager;
}

rm_release :: proc (using manager: ^ResourceManager) {
	delete(shaders);
	delete(textures);
}

rm_load_texture :: proc (using manager: ^ResourceManager, path: cstring, alpha: bool, name: string) -> (success: bool = true) {
	textures[name], success = rm_load_texture_from_file(manager, path, alpha);
	if !success do delete_key(&textures, name);
	return success;
}

rm_get_texture :: proc (using manager: ^ResourceManager, name: string) -> (texture: graphics.Texture2D, success: bool = true) {
	texture, success = textures[name];
	if !success do texture = graphics.Texture2D{};
	return texture, success;
}

rm_load_shader :: proc (using manager: ^ResourceManager, vs_path: string, fs_path: string, name: string) -> (success: bool = true) {
	shaders[name], success = rm_load_shader_from_file(manager, vs_path, fs_path);
	if !success do delete_key(&shaders, name);
	return success;
}

rm_get_shader :: proc (using manager: ^ResourceManager, name: string) -> (shader: graphics.Shader, success: bool = true) {
	shader, success = shaders[name];
	if !success do shader = 0;
	return shader, success;
}

@(private) 
rm_load_shader_from_file :: proc (using manager: ^ResourceManager, vs_path: string, fs_path: string) -> (shader: graphics.Shader, success: bool = true) {
    shader, success = gl.load_shaders_file(vs_path, fs_path);
	if !success do shader = 0;
	return shader, success;
}

@(private)
rm_load_texture_from_file :: proc (using manager: ^ResourceManager, path: cstring, alpha: bool) -> (texture: graphics.Texture2D, success: bool = true) {
	texture = graphics.texture_make();

	if alpha {
		texture.internal_format = gl.RGBA;
		texture.image_format = gl.RGBA;
	}

	width, height, n_channels: i32;
	stbi.set_flip_vertically_on_load(1); 
	data := stbi.load(path, &width, &height, &n_channels, 0);
	defer stbi.image_free(data);

	if data == nil {
		fmt.printf("Could not load texture!\n");
		success = false;
	}

	graphics.texture_generate(&texture, width, height, data);

	return texture, success;
}