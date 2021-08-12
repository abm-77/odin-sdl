package main

import sdl "shared:odin-sdl2"
import gl "shared:odin-gl"
import "core:fmt"
import "core:os"
import "core:mem"
import "core:math/linalg"
import "core:math"
import "world"
import "system"
import "system/input"
import "graphics"

App :: struct {
    window: ^sdl.Window,
    window_width, window_height: i32,
    gl_context: sdl.GL_Context,
    running: b32,
    resource_manager: system.ResourceManager,
}

init :: proc (width: i32 = 800, height: i32 = 600) -> (app: App) {
    using app;

    // SDL setup 
    if sdl.init(sdl.Init_Flags.Everything) < 0 {
        fmt.printf("could not initialize sdl\n");
    } 

    window_width = width;
    window_height = height;

    // GL hints
    sdl.gl_set_attribute(sdl.GL_Attr.Context_Profile_Mask, i32(sdl.GL_Context_Profile.Core));
    sdl.gl_set_attribute(sdl.GL_Attr.Context_Flags, i32(sdl.GL_Context_Flag.Forward_Compatible));
	sdl.gl_set_attribute(sdl.GL_Attr.Context_Major_Version, 3);
    sdl.gl_set_attribute(sdl.GL_Attr.Context_Minor_Version, 3);

    // create window
    if window = sdl.create_window (
        "Test window", 
        i32(sdl.Window_Pos.Undefined), i32(sdl.Window_Pos.Undefined),
        window_width, window_height,
        sdl.Window_Flags.Open_GL | sdl.Window_Flags.Shown,
    ); window == nil {
        fmt.printf("could not initialize sdl\n");
    } 

    // vsync
    sdl.gl_set_swap_interval(1);
    
    // GL context 
    if gl_context := sdl.gl_create_context(window); gl_context == nil {
        fmt.printf("could not initialize gl: %s \n", sdl.get_error());
    }

    // GL setup
    // load procedures
    gl.load_up_to(4, 5, proc(p: rawptr, name: cstring) do (cast(^rawptr)p)^ = sdl.gl_get_proc_address(name));

    // setup viewport
    gl.Viewport(0, 0, window_width, window_height);

    // blending for transparency
    gl.Enable(gl.BLEND);
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    gl.ClearColor (0.25, 0.5, 0.5, 1.0);

    load_resources(&app);

    running = true;

    return app;
}

load_resources :: proc (using app: ^App) {
    using system;
    resource_manager = rm_create();

    rm_load_texture(&resource_manager, rm_image_dir("awesomeface.png"), true, "face");
    rm_load_texture(&resource_manager, rm_image_dir("wall.jpg"), false, "wall");
    rm_load_texture(&resource_manager, rm_image_dir("tilesheet.png"), true, "tilesheet");
    rm_load_texture(&resource_manager, rm_image_dir("map_texture.png"), true, "map");

    rm_load_shader(&resource_manager, rm_shader_dir("sprite/sprite2.vert"), rm_shader_dir("sprite/sprite2.frag"), "sprite_unlit");
}

xx, yy: f32;
update :: proc (using app: ^App) {
    graphics.camera_set_position(&camera, xx, yy);

    e: sdl.Event;
    for sdl.poll_event(&e) != 0 {
        if e.type == sdl.Event_Type.Quit {
            running = false;
        }
		input.update_input_state(e);
    }

	if input.get_key_down(sdl.SDLK_w) {
		yy -= 1; 
	}
	if input.get_key_down(sdl.SDLK_s) {
		yy += 1; 
	}
	if input.get_key_down(sdl.SDLK_d) {
		xx += 1; 
	}
	if input.get_key_down(sdl.SDLK_a) {
		xx -= 1; 
	}
}

shutdown :: proc (using app: ^App) {
    system.rm_release(&resource_manager);
    sdl.destroy_window(window);
    sdl.quit();
}

camera: graphics.Camera;
main :: proc () {
    using game := init();
    defer shutdown(&game);
    
    texture1, _ := system.rm_get_texture(&resource_manager, "face");
    texture2, _ := system.rm_get_texture(&resource_manager, "wall");
    texture3, _ := system.rm_get_texture(&resource_manager, "tilesheet");
	map_texture, _ := system.rm_get_texture(&resource_manager, "map");
	level := world.load_map(&map_texture);

    shader_program, success := system.rm_get_shader(&resource_manager, "sprite_unlit");
    fmt.printf("shader_id: %s\n", shader_program);

    sprite1 := graphics.Sprite {
        &texture1,
        [2]f32 {0.5, 0.5},
        [2]f32 {0.25, 0.25},
    };
    sprite2 := graphics.Sprite {
        &texture2,
        [2]f32 {0, 0},
        [2]f32 {0.1, 0.1},
    };

    anim: graphics.AnimatedSprite;
    anim.texture = &texture3;
    anim.origin = {0, 0};
    anim.scale = {2, 2};

    graphics.animated_sprite_add_frame(&anim, {0,0}, {16,16}, 1000);
    graphics.animated_sprite_add_frame(&anim, {16,0}, {16,16}, 1000);
    graphics.animated_sprite_add_frame(&anim, {32,0}, {16,16}, 1000);
    graphics.animated_sprite_add_frame(&anim, {48,0}, {16,16}, 1000);
    graphics.animated_sprite_start(&anim);

    graphics.sprite_renderer_init(shader_program);
    camera.proj_matrix = linalg.matrix_ortho3d_f32 (0, f32(game.window_width), f32(game.window_height), 0, -1, 1);

	angle: f32 = 0;
    for running {
        using linalg;

        update(&game);            

        graphics.shader_bind(shader_program);
        view_proj_matrix := graphics.camera_get_view_proj_matrix(&camera);
        graphics.shader_set_mat4fv(shader_program, "u_ViewProjection", linalg.matrix_to_ptr(&view_proj_matrix));
        graphics.shader_bind(0);

        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        graphics.sprite_renderer_begin_batch();
		
		for row in 0..<world.MAP_WIDTH {
			for col in 0..<world.MAP_HEIGHT {
				tile := level[row][col];
				draw_pos := [2]f32{f32(col)* 51.2, f32(row) * 51.2};
				if  tile == world.TileType.TILE_WALL {
					graphics.sprite_renderer_draw_sprite(&sprite2, draw_pos, [4]f32{1,0,0,1});
				}
				else if tile == world.TileType.TILE_GRASS {
					graphics.sprite_renderer_draw_sprite(&sprite2, draw_pos, [4]f32{0,1,0,1});
				}
			}
		}

        graphics.sprite_renderer_draw_sprite(&sprite1, input.mouse_screen_position(&camera));
        graphics.sprite_renderer_draw_sprite(&sprite2, [2]f32{200, 400});

		angle += 1;
        graphics.sprite_renderer_draw_sprite(&anim, [2]f32{300, 300}, [4]f32{1,1,1,1}, angle);

        graphics.sprite_renderer_end_batch();
        graphics.sprite_renderer_flush();

        sdl.gl_swap_window(window);
    }

}
