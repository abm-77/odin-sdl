package graphics

import gl "shared:odin-gl"

import "core:fmt"
import "core:mem"
import "core:math"
import "core:math/linalg"

MAX_QUADS :: 1000;
MAX_VERTICES :: MAX_QUADS * 4;
MAX_INDICES :: MAX_QUADS * 6;
MAX_TEXTURES :: 16;

Quad :: [4]Vertex;

Vertex :: struct {
    position: [3]f32,
    color: [4]f32,
    tex_coords: [2]f32,
    tex_idx: f32,
}

Texture2D :: struct {
    id: u32,
    width, height: i32,
    internal_format: i32,
    image_format: u32,

    wrap_s: i32,
    wrap_t: i32,
    filter_min: i32,
    filter_max: i32,
}

Sprite :: struct {
    texture: Texture2D,
    origin: [2]f32,
    position: [2]f32,
    scale: [2]f32,
    rotation: f32,
    color: [4]f32,
}

SpriteRenderer :: struct {
   shader_program: u32,

   quad_vao: u32, 
   quad_vbo: u32,
   quad_ibo: u32,

   white_texture: Texture2D,
   white_texture_slot: u32,

   index_count: i32,

   quad_buffer: [MAX_VERTICES]Vertex,
   quad_buffer_index: u32,

   texture_slots: [MAX_TEXTURES]u32,
   texture_slot_index: u32,
}

@(private)
sprite_renderer : SpriteRenderer;

v2_rotate_about_v2 :: proc (point, origin: [2]f32, angle : f32) -> (result: [2]f32) {
    s := math.sin(angle);
    c := math.cos(angle);

    result = point;
    result.x -= origin.x;
    result.y -= origin.y;

    xnew := result.x * c - result.y * s;
    ynew := result.x * s + result.y * c;

    result.x = xnew + origin.x;
    result.y = ynew + origin.y;

    return result;
}

texture_make :: proc () -> (texture: Texture2D) {
    gl.GenTextures(1, &texture.id);
    texture.width = 0;
    texture.height = 0;
    texture.internal_format = gl.RGB;
    texture.image_format = gl.RGB;
    texture.wrap_s = gl.REPEAT;
    texture.wrap_t = gl.REPEAT;
    texture.filter_min = gl.LINEAR;
    texture.filter_max = gl.LINEAR;
    return texture;
}

texture_generate :: proc (texture: ^Texture2D, width: i32, height: i32, data: rawptr) {
    texture.width = width;
    texture.height = height;

    // bind texture
    gl.BindTexture(gl.TEXTURE_2D, texture.id);

    // set texture wrap and filter modes
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, texture.wrap_s);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, texture.wrap_t);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, texture.filter_min);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, texture.filter_max);

    // create texture
    gl.TexImage2D(gl.TEXTURE_2D, 0, texture.internal_format, width, height, 0, texture.image_format, gl.UNSIGNED_BYTE, data);

    // unbind texture
    gl.BindTexture(gl.TEXTURE_2D, 0);
}

texture_bind :: proc (texture: Texture2D) {
	gl.BindTexture(gl.TEXTURE_2D, texture.id);
}

quad_create :: proc (x: f32, y: f32, tex_id: f32) -> (quad: Quad) {
    size :: 1;
    white :: [4]f32 {1.0, 1.0, 1.0, 1.0}; 

    quad[0] = Vertex {
        [3]f32 {x, y, 0},
        white,
        [2]f32 {0, 0},
        tex_id,
    };

    quad[1] = Vertex {
        [3]f32 {x + size, y, 0},
        white,
        [2]f32 {1.0, 0},
        tex_id,
    };

    quad[2] = Vertex {
        [3]f32 {x + size, y + size, 0},
        white,
        [2]f32 {1.0, 1.0},
        tex_id,
    };

    quad[3] = Vertex {
        [3]f32 {x, y + size, 0},
        white,
        [2]f32 {0, 1.0},
        tex_id,
    };

    return quad;
}

sprite_renderer_init :: proc (shader: Shader) {
    using sprite_renderer;

    // Create Vertex Array Object
    gl.GenVertexArrays(1, &quad_vao);
    gl.BindVertexArray(quad_vao);

    // Vertex Buffer & Layout
    gl.GenBuffers(1, &quad_vbo);
    gl.BindBuffer(gl.ARRAY_BUFFER, quad_vao);
    gl.BufferData(gl.ARRAY_BUFFER, MAX_VERTICES * size_of(Vertex), nil, gl.STATIC_DRAW);

    gl.EnableVertexAttribArray(0);
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), nil);
    
    gl.EnableVertexAttribArray(1);
    gl.VertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, size_of(Vertex), rawptr(uintptr(12)));

    gl.EnableVertexAttribArray(2);
    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), rawptr(uintptr(28)));

    gl.EnableVertexAttribArray(3);
    gl.VertexAttribPointer(3, 1, gl.FLOAT, gl.FALSE, size_of(Vertex), rawptr(uintptr(36)));

    // Index Buffer Array
    offset : u32 = 0;
    indices :  [MAX_INDICES]u32;
    for i := 0; i < MAX_INDICES; i += 6 {
        indices[i + 0] = 0 + offset;
        indices[i + 1] = 1 + offset;
        indices[i + 2] = 2 + offset;

        indices[i + 3] = 2 + offset;
        indices[i + 4] = 3 + offset;
        indices[i + 5] = 0 + offset;

        offset += 4;
    }

    gl.GenBuffers(1, &quad_ibo);
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, quad_ibo);
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW);

    // Texture Slots
    white_texture = texture_make(); 
    fmt.printf("white %d\n", white_texture.id);
    white_texture.internal_format = gl.RGBA8;
    color := 0xffffffff;
    texture_generate(&white_texture, 1, 1, &color);
    texture_slots[0] = white_texture.id;
    texture_slot_index = 1;

    shader_program = shader;
    shader_bind(shader_program);
    samplers: [MAX_TEXTURES] i32;
    for i : i32 = 0; i < MAX_TEXTURES; i += 1 {
        samplers[i] = i;
    }
    shader_set_samplerv(shader_program, "u_Textures", MAX_TEXTURES, &samplers[0]);

    // Unbind Everything
    gl.BindVertexArray(0);
    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);

}

sprite_renderer_shutdown :: proc () {
    using sprite_renderer;
    gl.DeleteVertexArrays(1, &quad_vao);
    gl.DeleteBuffers(1, &quad_vbo);
    gl.DeleteBuffers(1, &quad_ibo);
    gl.DeleteTextures(1, &white_texture.id);
}

sprite_renderer_begin_batch :: proc () {
    using sprite_renderer;
    quad_buffer_index = 0;
}

sprite_renderer_end_batch :: proc () {
    using sprite_renderer;
    size := quad_buffer_index * size_of(Vertex);
    gl.BindBuffer(gl.ARRAY_BUFFER, quad_vbo);
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, int(size), &quad_buffer);
}

sprite_renderer_flush :: proc () {
   using sprite_renderer;

   shader_bind(shader_program);
   for i : u32 = 0; i < texture_slot_index; i += 1 {
       gl.ActiveTexture(gl.TEXTURE0 + i);
       gl.BindTexture(gl.TEXTURE_2D, texture_slots[i]);
   }

   gl.BindVertexArray(quad_vao);
   gl.DrawElements(gl.TRIANGLES, index_count, gl.UNSIGNED_INT, nil);

   index_count = 0;
   texture_slot_index = 1;
}

@(private)
sprite_renderer_draw_quad_color :: proc (position: [2]f32, size: [2]f32, color: [4]f32) {
    using sprite_renderer;

    if index_count >= MAX_INDICES {
        sprite_renderer_end_batch();
        sprite_renderer_flush();
        sprite_renderer_begin_batch();
    }

    tex_idx : f32 = 0;
    quad_buffer[quad_buffer_index] = Vertex {
        [3]f32 {position.x, position.y, 0},
        color,
        [2]f32 {0, 0},
        tex_idx,
    };
    quad_buffer_index += 1;

    quad_buffer[quad_buffer_index] = Vertex {
        [3]f32 {position.x + size.x, position.y, 0},
        color,
        [2]f32 {1.0, 0},
        tex_idx,
    };
    quad_buffer_index += 1;

    quad_buffer[quad_buffer_index] = Vertex {
        [3]f32 {position.x + size.x, position.y + size.y, 0},
        color,
        [2]f32 {1.0, 1.0},
        tex_idx,
    };
    quad_buffer_index += 1;

    quad_buffer[quad_buffer_index] = Vertex {
        [3]f32 {position.x, position.y + size.y, 0},
        color,
        [2]f32 {0, 1.0},
        tex_idx,
    };
    quad_buffer_index += 1;

    index_count += 6;
}

@(private)
sprite_renderer_draw_quad_texture :: proc (position: [2]f32, size: [2]f32, color: [4]f32, texture_id: u32, origin: [2]f32 = {0, 0}, rotation: f32 = 0) {
    using sprite_renderer;

    if index_count >= MAX_INDICES || texture_slot_index > MAX_TEXTURES - 1 {
        sprite_renderer_end_batch();
        sprite_renderer_flush();
        sprite_renderer_begin_batch();
    }

    tex_idx : f32 = -1;
    for i: u32 = 1; i < texture_slot_index; i += 1 {
        if texture_slots[i] == texture_id {
            tex_idx = f32(i);
            break;
        }
    }

    if tex_idx < 0 {
        tex_idx = f32 (texture_slot_index);
        texture_slots[texture_slot_index] = texture_id;
        texture_slot_index += 1;
    }

    draw_position := position - (origin * size);
    quad_buffer[quad_buffer_index] = Vertex {
        [3]f32 {draw_position.x, draw_position.y, 0},
        color,
        [2]f32 {0, 0},
        tex_idx,
    };
    quad_buffer_index += 1;

    tr := v2_rotate_about_v2([2]f32{draw_position.x + size.x, draw_position.y}, draw_position, math.to_radians(f32(rotation)));
    quad_buffer[quad_buffer_index] = Vertex {
        [3]f32 {tr.x, tr.y, 0},
        color,
        [2]f32 {1.0, 0},
        tex_idx,
    };
    quad_buffer_index += 1;

    br := v2_rotate_about_v2([2]f32{draw_position.x + size.x, draw_position.y + size.y}, draw_position, math.to_radians(f32(rotation)));
    quad_buffer[quad_buffer_index] = Vertex {
        [3]f32 {br.x, br.y, 0},
        color,
        [2]f32 {1.0, 1.0},
        tex_idx,
    };
    quad_buffer_index += 1;

    bl := v2_rotate_about_v2([2]f32{draw_position.x, draw_position.y + size.y}, draw_position, math.to_radians(f32(rotation)));
    quad_buffer[quad_buffer_index] = Vertex {
        [3]f32 {bl.x, bl.y, 0},
        color,
        [2]f32 {0, 1.0},
        tex_idx,
    };
    quad_buffer_index += 1;

    index_count += 6;
}

@(private)
sprite_renderer_draw_quad :: proc {
    sprite_renderer_draw_quad_color,
    sprite_renderer_draw_quad_texture,
};


sprite_renderer_draw_sprite :: proc (using sprite: ^Sprite) {
    using sprite_renderer;
    sprite_renderer_draw_quad(position, [2]f32{f32(texture.width) * scale.x,f32(texture.height) * scale.y} , color, texture.id, origin, rotation);
}