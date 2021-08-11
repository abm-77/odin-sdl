package world

import "../system"
import "../graphics"
import "core:fmt"

Scene :: struct {
	renderer: graphics.SpriteRenderer,
	camera: graphics.Camera,
}

TileType :: enum {
	TILE_INVALID,
	TILE_GRASS,
	TILE_COUNT,
}

// maps are loaded from textures, colors correspond to specific tiles
Map :: struct {
	width: i32,
	height: i32,
	tiles: [4][4] TileType,	
}

load_map :: proc (map_data: ^graphics.Texture2D) {
	// 4 parts per color (RGBA), each part is 1 byte, width x height number of pixels
	l :: 4 * 4 * 4;
	pixels : [l] byte;
	graphics.get_texture_data(map_data, map_data.image_format, &pixels);

	color_part := 0;
	for i in 0..l-1 {
		color_part += 1;
		fmt.printf("%d, ", pixels[i]);

		if color_part == 4 {
			color_part = 0;
			fmt.printf("\n");
		}
	}
}

