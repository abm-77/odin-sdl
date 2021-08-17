package world

import "../system"
import "../graphics"

import "core:fmt"
import "core:mem"

MAP_WIDTH :: 32;
MAP_HEIGHT :: 24;
TILE_SIZE :: 32;

Scene :: struct {
	renderer: graphics.SpriteRenderer,
	camera: graphics.Camera,
	tile_map: TileMap,
}

TileType :: enum u32 {
	TILE_INVALID,
	TILE_BLANK,
	TILE_GRASS,
	TILE_WALL,
}

Tile :: struct {
	tile_type: TileType,
	src_pos: [2]f32,
	src_size: [2]f32,	
	solid: b32,
}

TileMap :: struct {
	tile_sheet: ^graphics.Sprite,
	grid: [MAP_HEIGHT][MAP_WIDTH] Tile,
}

MapConfig :: map[u32]Tile;

// TODO(bryson): in the future, we can have variable sized maps, however most of the time
// the maps are going to all be the same size.
// maps are loaded from textures, colors correspond to specific tiles
// warning: this will free the map config
map_load :: proc (map_data: ^graphics.Texture2D, map_config: MapConfig, tile_sheet: ^graphics.Sprite) -> (loaded_map: TileMap) {
	loaded_map.tile_sheet = tile_sheet;

	// 4 parts per color (RGBA), each part is 1 byte, width x height number of pixels
	pixels : [4 * MAP_WIDTH * MAP_HEIGHT] byte;
	graphics.texture_get_data(map_data, map_data.image_format, &pixels);

	for row in 0..<MAP_HEIGHT {
		for col in 0..<MAP_WIDTH {
			// loop through rgba data for pixel (essentially we transform [4]u8 -> u32 by bit operations)
			alpha_offset := ((col + (row * MAP_WIDTH)) * 4) + 3; // current_pixel  (col + (row * MAP_WIDTH))
			pixel_color := u32(pixels[alpha_offset]);
			for color_offset in 1..3 do pixel_color |= u32(pixels[alpha_offset - color_offset]) << u32(color_offset * 8);
			loaded_map.grid[row][col] = map_config[pixel_color];
		}
	}

	delete(map_config);
	return loaded_map;
}

map_get_adjacent_tiles :: proc (tile_map: ^TileMap, row: int, col: int) -> (left, right, above, below: Tile, types: bit_set[TileType]) {
	left  =		(col - 1 > 0) 			? tile_map.grid[row][col - 1] : Tile{};
	right = 	(col + 1 < MAP_WIDTH) 	? tile_map.grid[row][col + 1] : Tile{};
	above = 	(row - 1 > 0) 			? tile_map.grid[row - 1][col] : Tile{};
	below = 	(row + 1 < MAP_HEIGHT)	? tile_map.grid[row + 1][col] : Tile{};
	types = {left.tile_type, right.tile_type, above.tile_type, below.tile_type};
	return left, right, above, below, types;
}

map_generate_collision_bounds :: proc (tile_map: ^TileMap) {
	rects: [dynamic]CollisionRect;
	visited: [MAP_WIDTH * MAP_HEIGHT]b32;

	for row in 0..<MAP_HEIGHT {
		for col in 0..<MAP_WIDTH {
			cell := col + row * MAP_WIDTH;
			if visited[cell] do continue;
			visited[cell] = true;

			if tile_map.grid[row][col].solid  == true {
				left, right, above, below, adj_types := map_get_adjacent_tiles(tile_map, row, col);
				if TileType.TILE_BLANK not_in adj_types do continue;

				curr_rect: CollisionRect;
				curr_rect.min = {f32(col * TILE_SIZE), f32(row * TILE_SIZE)};
				curr_rect.max = curr_rect.min + {TILE_SIZE, TILE_SIZE};

				_,_,_,_, right_adj := map_get_adjacent_tiles(tile_map, row, col + 1);
				_,_,_,_, below_adj := map_get_adjacent_tiles(tile_map, row + 1, col);

				if right.tile_type != TileType.TILE_INVALID && right.solid && TileType.TILE_BLANK in right_adj {
					curr_index := col+1;
					for curr_index < MAP_WIDTH {
						visited[curr_index + row * MAP_WIDTH] = true;
						_,_,_,_, ts := map_get_adjacent_tiles(tile_map, row, curr_index);
						if TileType.TILE_BLANK not_in ts || tile_map.grid[row][curr_index].tile_type == TileType.TILE_BLANK do break;
						curr_rect.max.x += TILE_SIZE;	
						curr_index += 1;
					}
					curr_rect.max.x -= TILE_SIZE;	
				}
				else if below.tile_type != TileType.TILE_INVALID && below.solid && TileType.TILE_BLANK in below_adj {
					curr_index := row+1;
					for curr_index < MAP_HEIGHT {
						visited[col + curr_index * MAP_WIDTH] = true;
						_,_,_,_, ts := map_get_adjacent_tiles(tile_map, curr_index, col);
						if TileType.TILE_BLANK not_in ts || tile_map.grid[curr_index][col].tile_type == TileType.TILE_BLANK do break;
						curr_rect.max.y += TILE_SIZE;	
						curr_index += 1;
					}
					curr_rect.max.y -= TILE_SIZE;	
				}
				append(&rects, curr_rect);
			}
		}
	}

	for rect in rects {
		fmt.printf("(%f, %f) -> (%f, %f)\n", rect.min.x / 32, rect.min.y / 32, rect.max.x / 32, rect.max.y / 32);
	}
}

map_draw :: proc (tile_map: ^TileMap) {
	for row in 0..<MAP_HEIGHT {
		for col in 0..<MAP_WIDTH {
			tile := tile_map.grid[row][col];
			draw_pos := [2]f32{f32(col) * TILE_SIZE, f32(row) * TILE_SIZE};
			graphics.sprite_renderer_draw_static_sprite_cropped(tile_map.tile_sheet, tile.src_pos, tile.src_size, draw_pos);
		}
	}
}