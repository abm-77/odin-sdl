package main

import sdl "shared:odin-sdl2"
import gl "shared:odin-gl"

import "core:fmt"
import "core:os"
import "core:math/linalg"

import "graphics"

App :: struct {
    window: ^sdl.Window,
    gl_context: sdl.GL_Context,
    running: b32,
}

init :: proc (window_width: i32 = 800, window_height: i32 = 600) -> (app: App) {
    using app;

    // SDL setup 
    if sdl.init(sdl.Init_Flags.Everything) < 0 {
        fmt.printf("could not initialize sdl\n");
    } 

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
    gl.load_up_to(4, 5, proc(p: rawptr, name: cstring) do (cast(^rawptr)p)^ = sdl.gl_get_proc_address(name));
    gl.Viewport(0, 0, window_width, window_height);

    running = true;

    return app;
}

update :: proc (using app: ^App) {
    e: sdl.Event;
    for sdl.poll_event(&e) != 0 {
        if e.type == sdl.Event_Type.Quit {
            running = false;
        }
    }
}

shutdown :: proc (using app: ^App) {
    sdl.destroy_window(window);
    sdl.quit();
}

main :: proc () {
    using game := init();
    defer shutdown(&game);

    vertices := [9]f32 {
        -0.5, -0.5, 0.0,
         0.5, -0.5, 0.0,
         0.0,  0.5, 0.0,
    };  

    vao, vbo: u32;
    gl.GenVertexArrays(1, &vao);
    gl.GenBuffers(1, &vbo);
    defer {
        gl.DeleteVertexArrays(1, &vao);
        gl.DeleteBuffers(1, &vbo);
    }

    gl.BindVertexArray(vao);
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW);

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), nil);
    gl.EnableVertexAttribArray(0);
    
    shader_program, success := gl.load_shaders_file("resources/shaders/default/default.vert", "resources/shaders/default/default.frag");
    if !success {
        fmt.printf("could not compile shader!\n");
    }

    for running {
        update(&game);

        gl.ClearColor(1.0, 1.0, 1.0, 1.0);
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        gl.UseProgram(shader_program);
        gl.BindVertexArray(vao);
        gl.DrawArrays(gl.TRIANGLES, 0, 3);

        sdl.gl_swap_window(window);
    }
}
