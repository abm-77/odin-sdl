#version 330 core

layout (location = 0) out vec4 o_Color;

in vec4 v_Color;
in vec2 v_TexCoord;
in float v_TexIndex;

uniform sampler2D u_Texture;

void main() {    
    int index = int(v_TexIndex);
    //o_Color = v_Color * texture(u_Texture, v_TexCoord);
    o_Color = vec4(1.0, 0.0, 0.0, 1.0);
}  