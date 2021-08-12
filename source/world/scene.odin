package world

import "../system"
import "../graphics"
import "core:fmt"
import "core:mem"

Scene :: struct {
	renderer: graphics.SpriteRenderer,
	camera: graphics.Camera,
}

TileType :: enum u32 {
	TILE_BLANK 	= 0x000000FF,
	TILE_GRASS 	= 0xFFFFFFFF,
	TILE_WALL 	= 0xFF0000FF,
}

// TODO(bryson): in the future, we can have variable sized maps, however most of the time
// the maps are going to all be the same size.
// maps are loaded from textures, colors correspond to specific tiles
MAP_WIDTH :: 4;
MAP_HEIGHT :: 4;
TileMap :: [MAP_WIDTH][MAP_HEIGHT] TileType;

load_map :: proc (map_data: ^graphics.Texture2D) -> (loaded_map: TileMap) {
	// 4 parts per color (RGBA), each part is 1 byte, width x height number of pixels
	pixels : [4 * MAP_WIDTH * MAP_HEIGHT] byte;
	graphics.texture_get_data(map_data, map_data.image_format, &pixels);
	for row in 0..<MAP_WIDTH {
		for col in 0..<MAP_HEIGHT {
			// loop through rgba data for pixel (essentially we transform [4]u8 -> u32 by bit operations)
			alpha_offset := ((col + (row * MAP_WIDTH)) * 4) + 3; // current_pixel  (col + (row * MAP_WIDTH))
			pixel_color: u32 = u32(pixels[alpha_offset]);
			for color_offset in 1..3 do pixel_color |= u32(pixels[alpha_offset - color_offset]) << u32(color_offset * 8);
			loaded_map[row][col] = TileType(pixel_color);
		}
	}
	return loaded_map;
}
